// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import { ISliceProductPrice } from "../Slice/interfaces/utils/ISliceProductPrice.sol";
import { IProductsModule } from "../Slice/interfaces/IProductsModule.sol";
import "./structs/AdditionalPriceParams.sol";
import "./structs/CurrenciesParams.sol";

/**
  @title Adjust product price based on custom input - Slice pricing strategy
  @author jj-ranalli
  @author Dom-Mac
  @notice
  - On product creation the creator can choose different inputs and associated additional prices
  - Inherits `ISliceProductPrice` interface
  - Constructor logic sets Slice contract addresses in storage
  - Storage-related logic was moved from the constructor into `setProductPrice` in implementations
  of this contract
  - Adds onlyProductOwner modifier used to verify sender's permissions on Slice before setting product params
 */

contract AdditionalPrice is ISliceProductPrice {
  //*********************************************************************//
  // ------------------------ immutable storage ------------------------ //
  //*********************************************************************//

  /**
    @notice
    Address of the Slice ProductsModule
  */
  address public immutable productsModuleAddress;

  //*********************************************************************//
  // ------------------------- mutable storage ------------------------- //
  //*********************************************************************//

  /**
    @notice
    Mapping from slicerId to productId to currency to AdditionalPriceParams
  */
  mapping(uint256 => mapping(uint256 => mapping(address => AdditionalPriceParams)))
    public productParams;

  //*********************************************************************//
  // -------------------------- constructor ---------------------------- //
  //*********************************************************************//

  constructor(address _productsModuleAddress) {
    productsModuleAddress = _productsModuleAddress;
  }

  //*********************************************************************//
  // ----------------------------- modifiers --------------------------- //
  //*********************************************************************//

  /**
    @notice
    Check if msg.sender is owner of a product. Used to manage access of `setProductPrice`
    in implementations of this contract.
  */
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

  //*********************************************************************//
  // ---------------------- external transactions ---------------------- //
  //*********************************************************************//

  /**
    @notice 
    Set customInputId and AdditionalPrice for product.
    
    @param _slicerId ID of the slicer to set the price params for.
    @param _productId ID of the product to set the price params for.
  */
  function setProductPrice(
    uint256 _slicerId,
    uint256 _productId,
    CurrenciesParams[] memory _currenciesParams
  ) external onlyProductOwner(_slicerId, _productId) {
    /// Add reference for currency used in loop
    CurrencyAdditionalParams[] memory _currencyAdd;

    /// For each strategy, grouped by currency
    for (uint256 i; i < _currenciesParams.length; ) {
      /// Access to AdditionalPriceParams for a specific slice, product and currency
      AdditionalPriceParams storage params = productParams[_slicerId][
        _productId
      ][_currenciesParams[i].currency];

      /// Save currency base price and strategy values
      params.basePrice = _currenciesParams[i].basePrice;
      params.strategy = _currenciesParams[i].strategy;
      params.dependsOnQuantity = _currenciesParams[i].dependsOnQuantity;

      /// Store reference for currency used in loop
      _currencyAdd = _currenciesParams[i].additionalPrices;
      /// Set additional values for each customInputId
      for (uint256 j; j < _currencyAdd.length; ) {
        /// Revert if customInputId == 0
        if (_currencyAdd[j].customInputId == 0) revert();

        /// Save the additional value for the j input
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

  //*********************************************************************//
  // -------------------------- public views --------------------------- //
  //*********************************************************************//

  /**
    @notice 
    Function called by Slice protocol to calculate current product price.
    Base price is returned if data is missing or customId is zero.

    @param _slicerId ID of the slicer being queried
    @param _productId ID of the product being queried
    @param _currency Currency chosen for the purchase
    @param _quantity Number of units purchased
    @return ethPrice and currencyPrice of product.
   */
  function productPrice(
    uint256 _slicerId,
    uint256 _productId,
    address _currency,
    uint256 _quantity,
    address,
    bytes memory data /// data in here corresponds to the choosen customId
  ) public view override returns (uint256 ethPrice, uint256 currencyPrice) {
    /// get basePrice, strategy and dependsOnQuantity from storage
    uint256 basePrice = productParams[_slicerId][_productId][_currency].basePrice;
    Strategy strategy = productParams[_slicerId][_productId][_currency].strategy;
    bool dependsOnQuantity = productParams[_slicerId][_productId][_currency].dependsOnQuantity;
    /// decode the customId from byte to uint
    uint256 customId = abi.decode(data, (uint256));

    /// based on the strategy additionalPrice price represents a value or a %
    uint256 additionalPrice;
    /// if customId is 0 additionalPrice is 0, this function returns the basePrice * quantity
    /// TODO: validate customId = 0 logic
    if (customId != 0) {
      additionalPrice = productParams[_slicerId][_productId][_currency]
        .additionalPrices[customId];
    }

    /// get price depending on rules
    uint256 price = additionalPrice != 0 
      ? strategy == Strategy.Custom 
      ? _quantity * basePrice + additionalPrice // if additionalPrice is 
      : (_quantity + additionalPrice/100) * basePrice
      : _quantity * basePrice;

    /// TODO: validate and comment strategies
      if (additionalPrice != 0 ) {
        if (strategy == Strategy.Custom ) {
          price = dependsOnQuantity 
          ? _quantity * (basePrice + additionalPrice) 
          : _quantity * basePrice + additionalPrice;
        } else if (strategy == Strategy.Percentage) {
          price = dependsOnQuantity 
          ? (_quantity + additionalPrice/100) * basePrice 
          : (_quantity + additionalPrice/100);
        } else {
          price = _quantity * basePrice;
        }
      } else {
        price = _quantity * basePrice;
      }

    // Set ethPrice or currencyPrice based on chosen currency
    if (_currency == address(0)) {
      ethPrice = price;
    } else {
      currencyPrice = price;
    }
  }
}
