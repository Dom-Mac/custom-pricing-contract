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

  address public immutable _productsModuleAddress;
  // Mapping from slicerId to productId to currency to AdditionalPriceParams
  mapping(uint256 => mapping(uint256 => mapping(address => AdditionalPriceParams)))
    public _productParams;

  /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

  constructor(address productsModuleAddress) {
    _productsModuleAddress = productsModuleAddress;
  }

  /*//////////////////////////////////////////////////////////////
                              MODIFIERS
  //////////////////////////////////////////////////////////////*/

  /// @notice Check if msg.sender is owner of a product. Used to manage access of `setProductPrice`
  /// in implementations of this contract.
  modifier onlyProductOwner(uint256 slicerId, uint256 productId) {
    require(
      IProductsModule(_productsModuleAddress).isProductOwner(
        slicerId,
        productId,
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
  /// @param slicerId ID of the slicer to set the price params for.
  /// @param productId ID of the product to set the price params for.

  function setProductPrice(
    uint256 slicerId,
    uint256 productId,
    CurrenciesParams[] memory currenciesParams
  ) external onlyProductOwner(slicerId, productId) {
    // Add reference for currency used in loop
    CurrencyAdditionalParams[] memory currencyAdd;

    // Set currency params for each currency
    for (uint256 i; i < currenciesParams.length; ) {
      AdditionalPriceParams storage params = _productParams[slicerId][
        productId
      ][currenciesParams[i].currency];

      // Set product params
      params.basePrice = currenciesParams[i].basePrice;
      params.strategy = currenciesParams[i].strategy;
      params.dependsOnQuantity = currenciesParams[i].dependsOnQuantity;

      // Store reference for currency used in loop
      currencyAdd = currenciesParams[i].additionalPrices;
      // Set additional values for each customInputId
      for (uint256 j; j < currencyAdd.length; ) {
        if (currencyAdd[j].customInputId == 0) revert();

        params.additionalPrices[currencyAdd[j].customInputId] = currencyAdd[j]
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
   * @param slicerId ID of the slicer being queried
   * @param productId ID of the product being queried
   * @param currency Currency chosen for the purchase
   * @param quantity Number of units purchased
   * @return ethPrice and currencyPrice of product.
   */
  function productPrice(
    uint256 slicerId,
    uint256 productId,
    address currency,
    uint256 quantity,
    address,
    bytes memory data
  ) public view override returns (uint256 ethPrice, uint256 currencyPrice) {
    uint256 basePrice = _productParams[slicerId][productId][currency].basePrice;
    uint256 customId = abi.decode(data, (uint256));

    uint256 additionalPrice;
    if (customId != 0) {
      additionalPrice = _productParams[slicerId][productId][currency]
        .additionalPrices[customId];
    }

    uint256 price = additionalPrice != 0
      ? quantity * basePrice + additionalPrice
      : quantity * basePrice;

    // Set ethPrice or currencyPrice based on chosen currency
    if (currency == address(0)) {
      ethPrice = price;
    } else {
      currencyPrice = price;
    }
  }
}
