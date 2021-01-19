// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

interface TokenSwap {
    function swapExactTokensForTokens(
        uint256 amountIn, 
        uint256 amountOutMin, 
        address[] calldata path, 
        address to, 
        uint256 deadline) external returns (uint[] memory);
}