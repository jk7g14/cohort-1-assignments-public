// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.30;

import {Script, console} from 'forge-std/Script.sol';
import {MiniAMMFactory} from '../src/MiniAMMFactory.sol';
import {MiniAMM} from '../src/MiniAMM.sol';
import {MockERC20} from '../src/MockERC20.sol';

contract FactoryScript is Script {
    MiniAMMFactory public miniAMMFactory;
    MockERC20 public token0;
    MockERC20 public token1;
    address public pair;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        // Step 1: Deploy MiniAMMFactory
        miniAMMFactory = new MiniAMMFactory();
        console.log('MiniAMMFactory:', address(miniAMMFactory));

        // Step 2: Deploy two MockERC20 tokens
        token0 = new MockERC20('Token A', 'TKA');
        token1 = new MockERC20('Token B', 'TKB');
        console.log('Token0 (A):', address(token0));
        console.log('Token1 (B):', address(token1));

        // Step 3: Create a MiniAMM pair using the factory
        pair = miniAMMFactory.createPair(address(token0), address(token1));
        console.log('Pair:', pair);

        // Optional: show the ordered token addresses stored in the pair
        MiniAMM amm = MiniAMM(pair);
        console.log('Pair.tokenX:', amm.tokenX());
        console.log('Pair.tokenY:', amm.tokenY());

        // Write addresses to a txt file (tab-separated with header)
        string memory dir = 'script/output';
        vm.createDir(dir, true);
        string memory path = string(
            abi.encodePacked(dir, '/deployment_addresses.txt')
        );

        string memory content = string(
            abi.encodePacked(
                'MiniAMMFactory deployment address\n',
                vm.toString(address(miniAMMFactory)),
                '\n',
                'MockERC20 #1 deployment address\n',
                vm.toString(address(token0)),
                '\n',
                'MockERC20 #2 deployment address\n',
                vm.toString(address(token1)),
                '\n',
                'MiniAMM deployment address representing MockERC20 #1 & #2 pair\n',
                vm.toString(pair),
                '\n'
            )
        );
        vm.writeFile(path, content);
        console.log('Addresses written to:', path);

        vm.stopBroadcast();
    }
}
