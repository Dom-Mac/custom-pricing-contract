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

  function setUp() public {
    productsModule = new MockProductsModule();
    additionalPrice = new AdditionalPrice(address(productsModule));
  }

  function testSetProductPrice() public {
    /// set additional va custom inputs
    CurrencyAdditionalParams[]
      memory currencyAdditionalParams = new CurrencyAdditionalParams[](2);
    currencyAdditionalParams[0] = CurrencyAdditionalParams(0, 1000);
    currencyAdditionalParams[1] = CurrencyAdditionalParams(1, 2000);

    CurrenciesParams[] memory currenciesParams = new CurrenciesParams[](1);
    currenciesParams[0] = CurrenciesParams(
      address(0),
      100,
      currencyAdditionalParams
    );

    additionalPrice.setProductPrice(slicerId, productId, currenciesParams);

    (uint256 ethPrice, uint256 currencyPrice) = additionalPrice.getProductPrice(
      slicerId,
      productId,
      address(0),
      2
    );
    console.log(ethPrice, currencyPrice);
  }
}
