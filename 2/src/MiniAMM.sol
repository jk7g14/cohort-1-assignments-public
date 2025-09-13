// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.30;

import {IMiniAMM, IMiniAMMEvents} from './IMiniAMM.sol';
import {MiniAMMLP} from './MiniAMMLP.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';

// Add as many variables or functions as you would like
// for the implementation. The goal is to pass `forge test`.
contract MiniAMM is IMiniAMM, IMiniAMMEvents, MiniAMMLP {
    uint256 public k = 0;
    uint256 public xReserve = 0;
    uint256 public yReserve = 0;

    address public tokenX;
    address public tokenY;

    // implement constructor
    constructor(address _tokenX, address _tokenY) MiniAMMLP(_tokenX, _tokenY) {
        require(_tokenX != address(0), 'tokenX cannot be zero address');
        require(_tokenY != address(0), 'tokenY cannot be zero address');
        require(_tokenX != _tokenY, 'Tokens must be different');

        if (_tokenX < _tokenY) {
            tokenX = _tokenX;
            tokenY = _tokenY;
        } else {
            tokenX = _tokenY;
            tokenY = _tokenX;
        }
        // k, xReserve, yReserve already default to 0
    }

    // Helper function to calculate square root
    function sqrt(uint256 x) internal pure returns (uint256) {
        if (x == 0) return 0;
        uint256 z = (x + 1) / 2;
        uint256 y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
        return y;
    }

    // add parameters and implement function.
    // this function will determine the 'k'.
    function _addLiquidityFirstTime(
        uint256 xAmountIn,
        uint256 yAmountIn
    ) internal returns (uint256 lpMinted) {
        require(xAmountIn > 0 && yAmountIn > 0, 'Invalid amounts');

        // Pull tokens from provider
        IERC20(tokenX).transferFrom(msg.sender, address(this), xAmountIn);
        IERC20(tokenY).transferFrom(msg.sender, address(this), yAmountIn);

        // Initialize reserves and k
        xReserve = xAmountIn;
        yReserve = yAmountIn;
        k = xReserve * yReserve;

        // Mint LP tokens equal to geometric mean
        lpMinted = sqrt(xAmountIn * yAmountIn);
        _mintLP(msg.sender, lpMinted);
    }

    // add parameters and implement function.
    // this function will increase the 'k'
    // because it is transferring liquidity from users to this contract.
    function _addLiquidityNotFirstTime(
        uint256 xAmountIn
    ) internal returns (uint256 lpMinted) {
        require(xAmountIn > 0, 'Invalid amount');

        uint256 xBefore = xReserve;
        uint256 yBefore = yReserve;
        require(xBefore > 0 && yBefore > 0, 'No liquidity in pool');

        // Maintain ratio: yRequired = xIn * yReserve / xReserve
        uint256 yRequired = (xAmountIn * yBefore) / xBefore;

        // Pull tokens
        IERC20(tokenX).transferFrom(msg.sender, address(this), xAmountIn);
        IERC20(tokenY).transferFrom(msg.sender, address(this), yRequired);

        // Mint LP proportional to added share
        lpMinted = (totalSupply() * xAmountIn) / xBefore; // equals totalSupply * yRequired / yBefore
        _mintLP(msg.sender, lpMinted);

        // Update reserves and k
        xReserve = xBefore + xAmountIn;
        yReserve = yBefore + yRequired;
        k = xReserve * yReserve;
    }

    // complete the function. Should transfer LP token to the user.
    function addLiquidity(
        uint256 xAmountIn,
        uint256 yAmountIn
    ) external returns (uint256 lpMinted) {
        if (totalSupply() == 0) {
            lpMinted = _addLiquidityFirstTime(xAmountIn, yAmountIn);
        } else {
            lpMinted = _addLiquidityNotFirstTime(xAmountIn);
        }
        emit AddLiquidity(xAmountIn, yAmountIn);
        return lpMinted;
    }

    // Remove liquidity by burning LP tokens
    function removeLiquidity(
        uint256 lpAmount
    ) external returns (uint256 xAmount, uint256 yAmount) {
        require(lpAmount > 0, 'Invalid amount');
        uint256 supply = totalSupply();
        require(supply > 0, 'No liquidity in pool');

        // Proportional amounts
        xAmount = (xReserve * lpAmount) / supply;
        yAmount = (yReserve * lpAmount) / supply;

        // Burn LP from sender
        _burnLP(msg.sender, lpAmount);

        // Update reserves
        xReserve = xReserve - xAmount;
        yReserve = yReserve - yAmount;

        // Transfer underlying tokens out
        IERC20(tokenX).transfer(msg.sender, xAmount);
        IERC20(tokenY).transfer(msg.sender, yAmount);

        // Update k
        if (totalSupply() == 0) {
            k = 0;
        } else {
            k = xReserve * yReserve;
        }
    }

    // complete the function
    function swap(uint256 xAmountIn, uint256 yAmountIn) external {
        require(
            !(xAmountIn > 0 && yAmountIn > 0),
            'Can only swap one direction at a time'
        );
        require(xAmountIn > 0 || yAmountIn > 0, 'Must swap at least one token');
        require(xReserve > 0 && yReserve > 0, 'No liquidity in pool');

        uint256 xOut = 0;
        uint256 yOut = 0;

        if (xAmountIn > 0) {
            require(xAmountIn <= xReserve, 'Insufficient liquidity');
            // Pull token X in (full amount)
            IERC20(tokenX).transferFrom(msg.sender, address(this), xAmountIn);
            // Uniswap v2 formula with 0.3% fee
            uint256 amountInWithFee = (xAmountIn * 997);
            uint256 numerator = amountInWithFee * yReserve;
            uint256 denominator = (xReserve * 1000) + amountInWithFee;
            yOut = numerator / denominator;

            // Update reserves: full x in, y out
            xReserve = xReserve + xAmountIn;
            yReserve = yReserve - yOut;

            // Transfer Y out
            IERC20(tokenY).transfer(msg.sender, yOut);
        } else {
            require(yAmountIn <= yReserve, 'Insufficient liquidity');
            // Pull token Y in (full amount)
            IERC20(tokenY).transferFrom(msg.sender, address(this), yAmountIn);
            // Uniswap v2 formula with 0.3% fee
            uint256 amountInWithFee = (yAmountIn * 997);
            uint256 numerator = amountInWithFee * xReserve;
            uint256 denominator = (yReserve * 1000) + amountInWithFee;
            xOut = numerator / denominator;

            // Update reserves: full y in, x out
            yReserve = yReserve + yAmountIn;
            xReserve = xReserve - xOut;

            // Transfer X out
            IERC20(tokenX).transfer(msg.sender, xOut);
        }

        // Update k and emit event
        k = xReserve * yReserve;
        emit Swap(xAmountIn, yAmountIn, xOut, yOut);
    }
}
