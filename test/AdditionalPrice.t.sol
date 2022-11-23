// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

// import "forge-std/Test.sol";
import "lib/forge-std/src/Test.sol";
import "src/AdditionalPrice/AdditionalPrice.sol";
import { CurrenciesParams } from "src/AdditionalPrice/structs/CurrenciesParams.sol";
import { CurrencyAdditionalParams } from "src/AdditionalPrice/structs/CurrencyAdditionalParams.sol";
import { MockProductsModule } from "./mocks/MockProductsModule.sol";

uint256 constant slicerId = 0;
uint256 constant productId = 1;

contract TestAdditionalPrice is Test {
  MockProductsModule productsModule;
  AdditionalPrice additionalPrice;
  address _eth = address(0);
  uint256 _basePrice = 1000;
  uint256 _inputOneAddAmount = 100;
  uint256 _inputTwoAddAmount = 200;

  function setUp() public {
    productsModule = new MockProductsModule();
    additionalPrice = new AdditionalPrice(address(productsModule));

    /// set product price with additional custom inputs
    CurrencyAdditionalParams[]
      memory currencyAdditionalParams = new CurrencyAdditionalParams[](2);
    currencyAdditionalParams[0] = CurrencyAdditionalParams(
      1,
      _inputOneAddAmount
    );
    currencyAdditionalParams[1] = CurrencyAdditionalParams(
      2,
      _inputTwoAddAmount
    );

    CurrenciesParams[] memory currenciesParams = new CurrenciesParams[](1);
    currenciesParams[0] = CurrenciesParams(
      _eth,
      _basePrice,
      currencyAdditionalParams
    );
    additionalPrice.setProductPrice(slicerId, productId, currenciesParams);
  }

  /// @notice quantity is a uint128, uint256 causes overflow error
  function testProductPriceEth(uint128 quantity) public {
    uint256 _choosenId = 1;
    bytes memory customInputId = abi.encodePacked(_choosenId);

    (uint256 ethPrice, uint256 currencyPrice) = additionalPrice.productPrice(
      slicerId,
      productId,
      _eth,
      quantity,
      address(1),
      customInputId
    );

    assertEq(currencyPrice, 0);
    assertEq(ethPrice, quantity * _basePrice + _inputOneAddAmount);
  }

  /// @notice quantity is a uint128, uint256 causes overflow error
  /// @dev customInput 0 returns the base price
  function testProductBasePriceEth(uint128 quantity) public {
    uint256 _choosenId = 0;
    bytes memory customInputId = abi.encodePacked(_choosenId);

    (uint256 ethPrice, uint256 currencyPrice) = additionalPrice.productPrice(
      slicerId,
      productId,
      _eth,
      quantity,
      address(1),
      customInputId
    );

    assertEq(currencyPrice, 0);
    assertEq(ethPrice, quantity * _basePrice);
  }
}
