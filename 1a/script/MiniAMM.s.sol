// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.30;

import {Script, console} from 'forge-std/Script.sol';
import {MiniAMM} from '../src/MiniAMM.sol';
import {MockERC20} from '../src/MockERC20.sol';

contract MiniAMMScript is Script {
    MiniAMM public miniAMM;
    MockERC20 public token0;
    MockERC20 public token1;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        // Deploy mock ERC20 tokens
        token0 = new MockERC20('Flare Token A', 'FLRA');
        token1 = new MockERC20('Flare Token B', 'FLRB');

        // Deploy MiniAMM with the tokens
        miniAMM = new MiniAMM(address(token0), address(token1));

        // Log deployed addresses
        console.log('Token A deployed at:', address(token0));
        console.log('Token B deployed at:', address(token1));
        console.log('MiniAMM deployed at:', address(miniAMM));

        vm.stopBroadcast();
    }
}
