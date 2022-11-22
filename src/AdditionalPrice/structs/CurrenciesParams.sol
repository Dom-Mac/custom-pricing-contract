// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { CurrencyAdditionalParams } from "./CurrencyAdditionalParams.sol";

/// @param currency currency address for a product
/// @param basePrice base price for a currency
/// @param additionalPrices array of CurrencyAdditionalParams

struct CurrenciesParams {
  address currency;
  uint256 basePrice;
  CurrencyAdditionalParams[] additionalPrices;
}
