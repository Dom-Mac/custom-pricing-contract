// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

// import "forge-std/Test.sol";
import 'lib/forge-std/src/Test.sol';
import 'src/AdditionalPrice/AdditionalPrice.sol';
import 'src/AdditionalPrice/structs/CurrenciesParams.sol';
import 'src/AdditionalPrice/structs/CurrencyAdditionalParams.sol';
import {MockProductsModule} from './mocks/MockProductsModule.sol';

uint256 constant slicerId = 0;
uint256 constant productId = 1;

contract TestAdditionalPrice is Test {
  MockProductsModule productsModule;
  AdditionalPrice additionalPrice;
  address eth = address(0);
  uint256 basePrice = 1000;
  uint256 inputOneAddAmount = 100;
  uint256 inputTwoAddAmount = 200;

  function createPriceStrategy(Strategy _strategy, bool _dependsOnQuantity) public {
    CurrencyAdditionalParams[] memory _currencyAdditionalParams = new CurrencyAdditionalParams[](2);

    if (_strategy == Strategy.Custom) {
      /// set product price with additional custom inputs
      _currencyAdditionalParams[0] = CurrencyAdditionalParams(1, inputOneAddAmount);
      _currencyAdditionalParams[1] = CurrencyAdditionalParams(2, inputTwoAddAmount);
    } else if (_strategy == Strategy.Percentage) {}

    CurrenciesParams[] memory currenciesParams = new CurrenciesParams[](1);
    currenciesParams[0] = CurrenciesParams(
      eth,
      basePrice,
      _strategy,
      _dependsOnQuantity,
      _currencyAdditionalParams
    );
    additionalPrice.setProductPrice(slicerId, productId, currenciesParams);
  }

  function setUp() public {
    productsModule = new MockProductsModule();
    additionalPrice = new AdditionalPrice(address(productsModule));
  }

  /// @notice quantity is uint128, uint256 causes overflow error
  function testProductPriceEth(uint128 quantity) public {
    createPriceStrategy(Strategy.Custom, false);
    uint256 _choosenId = 1;
    bytes memory customInputId = abi.encodePacked(_choosenId);

    (uint256 ethPrice, uint256 currencyPrice) = additionalPrice.productPrice(
      slicerId,
      productId,
      eth,
      quantity,
      address(1),
      customInputId
    );

    assertEq(currencyPrice, 0);
    assertEq(ethPrice, quantity * basePrice + inputOneAddAmount);
  }

  /// @notice quantity is uint128, uint256 causes overflow error
  /// @dev customInput 0 -> the base price is returned
  function testProductBasePriceEth(uint128 quantity) public {
    createPriceStrategy(Strategy.Custom, false);
    uint256 _choosenId = 0;
    bytes memory customInputId = abi.encodePacked(_choosenId);

    (uint256 ethPrice, uint256 currencyPrice) = additionalPrice.productPrice(
      slicerId,
      productId,
      eth,
      quantity,
      address(1),
      customInputId
    );

    assertEq(currencyPrice, 0);
    assertEq(ethPrice, quantity * basePrice);
  }

  /// @dev non existing input returns the base price, quantity = 1
  function testNonExistingInput() public {
    createPriceStrategy(Strategy.Custom, false);
    uint256 _choosenId = 10;
    bytes memory customInputId = abi.encodePacked(_choosenId);

    (uint256 ethPrice, uint256 currencyPrice) = additionalPrice.productPrice(
      slicerId,
      productId,
      eth,
      1,
      address(1),
      customInputId
    );

    assertEq(currencyPrice, 0);
    assertEq(ethPrice, basePrice);
  }
}
