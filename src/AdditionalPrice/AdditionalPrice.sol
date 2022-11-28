// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import { ISliceProductPrice } from "../Slice/interfaces/utils/ISliceProductPrice.sol";
import { IProductsModule } from "../Slice/interfaces/IProductsModule.sol";
import "./structs/AdditionalPriceParams.sol";
import "./structs/CurrenciesParams.sol";

/// @title Adjust product price based on custom input - Slice pricing strategy
/// @author jj-ranalli
/// @author Dom-Mac
/// @notice
/// - On product creation the creator can choose different inputs and associated additional prices
/// - Inherits `ISliceProductPrice` interface
/// - Constructor logic sets Slice contract addresses in storage
/// - Storage-related logic was moved from the constructor into `setProductPrice` in implementations
/// of this contract
/// - Adds onlyProductOwner modifier used to verify sender's permissions on Slice before setting product params

contract AdditionalPrice is ISliceProductPrice {
  /*//////////////////////////////////////////////////////////////
                                STORAGE
  //////////////////////////////////////////////////////////////*/

  address public immutable productsModuleAddress;
  // Mapping from slicerId to productId to currency to AdditionalPriceParams
  mapping(uint256 => mapping(uint256 => mapping(address => AdditionalPriceParams)))
    public productParams;

  /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

  constructor(address _productsModuleAddress) {
    productsModuleAddress = _productsModuleAddress;
  }

  /*//////////////////////////////////////////////////////////////
                              MODIFIERS
  //////////////////////////////////////////////////////////////*/

  /// @notice Check if msg.sender is owner of a product. Used to manage access of `setProductPrice`
  /// in implementations of this contract.
  modifier onlyProductOwner(uint256 _slicerId, uint256 _productId) {
    require(
      IProductsModule(productsModuleAddress).isProductOwner(
        _slicerId,
        _productId,
        msg.sender
      ),
      "NOT_PRODUCT_OWNER"
    );
    _;
  }

  /*//////////////////////////////////////////////////////////////
                ADDITIONAL PRICE ON CUSTOM INPUTS
    //////////////////////////////////////////////////////////////*/

  /// @notice Set customInputId and AdditionalPrice for product.
  /// @param _slicerId ID of the slicer to set the price params for.
  /// @param _productId ID of the product to set the price params for.

  function setProductPrice(
    uint256 _slicerId,
    uint256 _productId,
    CurrenciesParams[] memory _currenciesParams
  ) external onlyProductOwner(_slicerId, _productId) {
    // Add reference for currency used in loop
    CurrencyAdditionalParams[] memory _currencyAdd;

    // Set currency params for each currency
    for (uint256 i; i < _currenciesParams.length; ) {
      AdditionalPriceParams storage params = productParams[_slicerId][
        _productId
      ][_currenciesParams[i].currency];

      // Set product params
      params.basePrice = _currenciesParams[i].basePrice;
      params.strategy = _currenciesParams[i].strategy;
      params.dependsOnQuantity = _currenciesParams[i].dependsOnQuantity;

      // Store reference for currency used in loop
      _currencyAdd = _currenciesParams[i].additionalPrices;
      // Set additional values for each customInputId
      for (uint256 j; j < _currencyAdd.length; ) {
        if (_currencyAdd[j].customInputId == 0) revert();

        params.additionalPrices[_currencyAdd[j].customInputId] = _currencyAdd[j]
          .additionalPrice;

        unchecked {
          ++j;
        }
      }

      unchecked {
        ++i;
      }
    }
  }

  /*//////////////////////////////////////////////////////////////
              CUSTOM ADDITIONAL PRICE 
  //////////////////////////////////////////////////////////////*/

  /**
   * @notice Function called by Slice protocol to calculate current product price.
   * Base price is returned if data is missing or customId is zero.
   * @param _slicerId ID of the slicer being queried
   * @param _productId ID of the product being queried
   * @param currency Currency chosen for the purchase
   * @param quantity Number of units purchased
   * @return ethPrice and currencyPrice of product.
   */
  function productPrice(
    uint256 _slicerId,
    uint256 _productId,
    address currency,
    uint256 quantity,
    address,
    bytes memory data /// data in here corresponds to the choosen customId
  ) public view override returns (uint256 ethPrice, uint256 currencyPrice) {
    /// get basePrice, strategy and dependsOnQuantity from storage
    uint256 basePrice = productParams[_slicerId][_productId][currency].basePrice;
    Strategy strategy = productParams[_slicerId][_productId][currency].strategy;
    bool dependsOnQuantity = productParams[_slicerId][_productId][currency].dependsOnQuantity;
    /// decode the customId from byte to uint
    uint256 customId = abi.decode(data, (uint256));

    /// based on the strategy additionalPrice price represents a value or a %
    uint256 additionalPrice;
    /// if customId is 0 additionalPrice is 0, this function returns the basePrice * quantity
    /// TODO: validate customId = 0 logic
    if (customId != 0) {
      additionalPrice = productParams[_slicerId][_productId][currency]
        .additionalPrices[customId];
    }

    /// get price depending on rules
    uint256 price = additionalPrice != 0 
      ? strategy == Strategy.Custom 
      ? quantity * basePrice + additionalPrice // if additionalPrice is 
      : (quantity + additionalPrice/100) * basePrice
      : quantity * basePrice;

    /// TODO: validate and comment strategies
      if (additionalPrice != 0 ) {
        if (strategy == Strategy.Custom ) {
          price = dependsOnQuantity 
          ? quantity * (basePrice + additionalPrice) 
          : quantity * basePrice + additionalPrice;
        } else if (strategy == Strategy.Percentage) {
          price = dependsOnQuantity 
          ? (quantity + additionalPrice/100) * basePrice 
          : (quantity + additionalPrice/100);
        } else {
          price = quantity * basePrice;
        }
      } else {
        price = quantity * basePrice;
      }

    // Set ethPrice or currencyPrice based on chosen currency
    if (currency == address(0)) {
      ethPrice = price;
    } else {
      currencyPrice = price;
    }
  }
}
