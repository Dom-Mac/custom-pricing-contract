// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import "src/AdditionalPrice/AdditionalPrice.sol";
import { MockProductsModule } from "./mocks/MockProductsModule.sol";

contract TestAdditionalPrice is Test {
  MockProductsModule productsModule;
  AdditionalPrice additionalPrice;
  uint256 constant slicerId = 0;
  uint256 constant productId = 1;

  function setUp() public {
    productsModule = new MockProductsModule();
    additionalPrice = new AdditionalPrice(address(productsModule));
  }

  function testSetProductPrice() public {
    additionalPrice.setProductPrice(slicerId, productId);
  }

  function testBar() public {
    assertEq(uint256(1), uint256(1), "ok");
  }

  function testFoo(uint256 x) public {
    vm.assume(x < type(uint128).max);
    assertEq(x + x, x * 2);
  }
}
