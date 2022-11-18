// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { AdditionalPriceParams } from "./AdditionalPriceParams.sol";

/// @param currency currency address for a product
/// @param basePrice base price for a currency
/// @param additionalPrices mapping from customInputId to additionalPrice

struct CurrenciesParams {
  address currency;
  uint256 basePrice;
  mapping(uint256 => uint256) additionalPrices;
} 