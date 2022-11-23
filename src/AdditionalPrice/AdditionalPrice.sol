// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import { ISliceProductPrice } from "../Slice/interfaces/utils/ISliceProductPrice.sol";
import { IProductsModule } from "../Slice/interfaces/IProductsModule.sol";
import { AdditionalPriceParams } from "./structs/AdditionalPriceParams.sol";
import { CurrenciesParams } from "./structs/CurrenciesParams.sol";

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

  address internal immutable _productsModuleAddress;
  // Mapping from slicerId to productId to currency to AdditionalPriceParams
  mapping(uint256 => mapping(uint256 => mapping(address => AdditionalPriceParams)))
    private _productParams;

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
    // Set currency params for each currency
    for (uint256 i; i < currenciesParams.length; ) {
      // Set product params
      _productParams[slicerId][productId][currenciesParams[i].currency]
        .basePrice = currenciesParams[i].basePrice;

      // Set additional values for each customInputId
      for (uint256 j; j < currenciesParams[i].additionalPrices.length; ) {
        _productParams[slicerId][productId][currenciesParams[i].currency]
          .additionalPrices[
            currenciesParams[i].additionalPrices[j].customInputId
          ] = currenciesParams[i].additionalPrices[j].additionalPrice;

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
    uint256 additionalPrice = _productParams[slicerId][productId][currency]
      .additionalPrices[customId];

    // Set ethPrice or currencyPrice based on chosen currency
    if (currency == address(0)) {
      ethPrice = quantity * basePrice + additionalPrice;
    } else {
      currencyPrice = quantity * basePrice + additionalPrice;
    }
  }
}
