// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.30;

import {IMiniAMM, IMiniAMMEvents} from './IMiniAMM.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';

// Add as many variables or functions as you would like
// for the implementation. The goal is to pass `forge test`.
contract MiniAMM is IMiniAMM, IMiniAMMEvents {
    uint256 public k = 0;
    uint256 public xReserve = 0;
    uint256 public yReserve = 0;

    address public tokenX;
    address public tokenY;

    // implement constructor
    constructor(address _tokenX, address _tokenY) {
        if (_tokenX == address(0)) revert('tokenX cannot be zero address');
        if (_tokenY == address(0)) revert('tokenY cannot be zero address');
        if (_tokenX == _tokenY) revert('Tokens must be different');

        if (_tokenX < _tokenY) {
            tokenX = _tokenX;
            tokenY = _tokenY;
        } else {
            tokenX = _tokenY;
            tokenY = _tokenX;
        }
    }

    // add parameters and implement function.
    // this function will determine the initial 'k'.
    function _addLiquidityFirstTime(
        uint256 xAmountIn,
        uint256 yAmountIn,
        address sender
    ) internal {
        IERC20(tokenX).transferFrom(sender, address(this), xAmountIn);
        IERC20(tokenY).transferFrom(sender, address(this), yAmountIn);

        xReserve = xAmountIn;
        yReserve = yAmountIn;

        k = xReserve * yReserve;

        emit AddLiquidity(xAmountIn, yAmountIn);
    }

    // add parameters and implement function.
    // this function will increase the 'k'
    // because it is transferring liquidity from users to this contract.
    function _addLiquidityNotFirstTime(
        uint256 xAmountIn,
        uint256 yAmountIn,
        address sender
    ) internal {
        uint256 yAmountInRequired = (xAmountIn * yReserve) / xReserve;
        require(yAmountIn == yAmountInRequired, 'Must maintain the same ratio');

        IERC20(tokenX).transferFrom(sender, address(this), xAmountIn);
        IERC20(tokenY).transferFrom(sender, address(this), yAmountIn);

        xReserve += xAmountIn;
        yReserve += yAmountInRequired;

        k = xReserve * yReserve;

        emit AddLiquidity(xAmountIn, yAmountIn);
    }

    // complete the function
    function addLiquidity(uint256 xAmountIn, uint256 yAmountIn) external {
        require(
            xAmountIn > 0 && yAmountIn > 0,
            'Amounts must be greater than 0'
        );
        if (k == 0) {
            // add params
            _addLiquidityFirstTime(xAmountIn, yAmountIn, msg.sender);
        } else {
            // add params
            _addLiquidityNotFirstTime(xAmountIn, yAmountIn, msg.sender);
        }
    }

    // complete the function
    function swap(uint256 xAmountIn, uint256 yAmountIn) external {
        require(k > 0, 'No liquidity in pool');
        require(
            !(xAmountIn > 0 && yAmountIn > 0),
            'Can only swap one direction at a time'
        );
        require(xAmountIn > 0 || yAmountIn > 0, 'Must swap at least one token');

        if (xAmountIn > 0) {
            // buy yToken
            require(xAmountIn < xReserve, 'Insufficient liquidity');

            // calculate yOut
            uint256 newX = xReserve + xAmountIn;
            uint256 yOut = yReserve - (k / newX);
            require(yOut > 0, 'Insufficient liquidity');

            // transfer xAmountIn from msg.sender to contract
            IERC20(tokenX).transferFrom(msg.sender, address(this), xAmountIn);

            xReserve = newX;
            yReserve -= yOut;
            k = xReserve * yReserve;

            IERC20(tokenY).transfer(msg.sender, yOut);

            emit Swap(xAmountIn, yOut);
        } else {
            // buy xToken
            require(yAmountIn < yReserve, 'Insufficient liquidity');

            uint256 newY = yReserve + yAmountIn;
            uint256 xOut = xReserve - (k / newY);
            require(xOut > 0, 'Insufficient liquidity');

            IERC20(tokenY).transferFrom(msg.sender, address(this), yAmountIn);

            xReserve -= xOut;
            yReserve = newY;
            k = xReserve * yReserve;

            IERC20(tokenX).transfer(msg.sender, xOut);

            emit Swap(xOut, yAmountIn);
        }
    }
}
