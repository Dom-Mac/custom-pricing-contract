// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @param basePrice base price for a currency
/// @param additionalPrices mapping from customInputId to additionalPrice

struct AdditionalPriceParams {
  uint256 basePrice;
  mapping(uint256 => uint256) additionalPrices;
}