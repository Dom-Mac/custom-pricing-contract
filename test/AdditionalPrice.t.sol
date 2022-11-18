// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import "src/AdditionalPrice/AdditionalPrice.sol";

contract TestAdditionalPrice is Test {
    AdditionalPrice a;

    function setUp() public {
        a = new AdditionalPrice();
    }

    function testBar() public {
        assertEq(uint256(1), uint256(1), "ok");
    }

    function testFoo(uint256 x) public {
        vm.assume(x < type(uint128).max);
        assertEq(x + x, x * 2);
    }
}
