// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../interfaces/IERC20.sol";

contract MockAavePool {
    IERC20 public immutable asset;
    IERC20 public immutable aToken;

    constructor(address _asset, address _aToken) {
        asset = IERC20(_asset);
        aToken = IERC20(_aToken);
    }

    function supply(address, uint256 amount, address onBehalfOf, uint16) external {
        require(asset.transferFrom(msg.sender, address(this), amount), "TRANSFER_FROM");
        // mint aTokens 1:1 (simulate yield by minting more in tests)
        (bool ok, ) = address(aToken).call(abi.encodeWithSignature("mint(address,uint256)", onBehalfOf, amount));
        require(ok, "MINT");
    }

    function withdraw(address, uint256 amount, address to) external returns (uint256) {
        // burn aTokens 1:1
        (bool ok1, ) = address(aToken).call(abi.encodeWithSignature("burn(address,uint256)", msg.sender, amount));
        require(ok1, "BURN");
        require(asset.transfer(to, amount), "TRANSFER");
        return amount;
    }
}
