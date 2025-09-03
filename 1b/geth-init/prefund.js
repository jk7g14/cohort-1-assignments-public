const from = eth.accounts[0];
const contractDeployer =
  process.env.DEPLOYER_ADDRESS || '0xDc5AAE0B55AA8DeD6fcbDec0d1f8CB321743Ce59';
eth.sendTransaction({
  from: from,
  to: contractDeployer,
  value: web3.toWei(100, 'ether'),
});
console.log('Prefunded 100 ETH to:', contractDeployer);
