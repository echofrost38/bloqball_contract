/**
 * Use this file to configure your truffle project. It's seeded with some
 * common settings for different networks and features like migrations,
 * compilation and testing. Uncomment the ones you need or modify
 * them to suit your project as necessary.
 *
 * More information about configuration can be found at:
 *
 * trufflesuite.com/docs/advanced/configuration
 *
 * To deploy via Infura you'll need a wallet provider (like @truffle/hdwallet-provider)
 * to sign your transactions before they're sent to a remote public node. Infura accounts
 * are available for free at: infura.io/register.
 *
 * You'll also need a mnemonic - the twelve word phrase the wallet uses to generate
 * public/private key pairs. If you're publishing your code to GitHub make sure you load this
 * phrase from a file you've .gitignored so it doesn't accidentally become public.
 *
 */

  const wrapProvider = require('arb-ethers-web3-bridge').wrapProvider;
 const HDWalletProvider = require('@truffle/hdwallet-provider');
 const fs = require('fs');
 const mnemonic = fs.readFileSync(".secret").toString().trim();
 
 module.exports = {
   /**
    * Networks define how you connect to your ethereum client and let you set the
    * defaults web3 uses to send transactions. If you don't specify one truffle
    * will spin up a development blockchain for you on port 9545 when you
    * run `develop` or `test`. You can ask a truffle command to use a specific
    * network from the command line, e.g
    *
    * $ truffle test --network <network-name>
    */

   networks: {
     harmonyTest: {
       provider: () => wrapProvider(new HDWalletProvider(mnemonic, 'https://api.s1.b.hmny.io')),
       network_id: 1666700001,
       skipDryRun: true,
       from: '0x0B88418E95fb05d742E526E869ee2404d7904F81',
     },
     arbitrumTest: {
       provider: () => wrapProvider(new HDWalletProvider(mnemonic, 'https://rinkeby.arbitrum.io/rpc')),
       network_id: 421611,
       skipDryRun: true,
       gas: 287853530,
       from: '0x0B88418E95fb05d742E526E869ee2404d7904F81',
     },
     rinkeby: {
       provider: () => new HDWalletProvider(mnemonic, `https://rinkeby.infura.io/v3/9aa3d95b3bc440fa88ea12eaa4456161`),
       network_id: 4,
       skipDryRun: true,
       from: '0x0B88418E95fb05d742E526E869ee2404d7904F81',
     },
     bscTest: {
       provider: () => new HDWalletProvider(mnemonic, `https://data-seed-prebsc-1-s1.binance.org:8545`),
       network_id: 97,
       timeoutBlocks: 120000,
       skipDryRun: true,
       from: '0x0B88418E95fb05d742E526E869ee2404d7904F81',
     },
     ropsten: {
       provider: () => new HDWalletProvider(mnemonic, `https://ropsten.infura.io/v3/9aa3d95b3bc440fa88ea12eaa4456161`),
       network_id: 3,
       timeoutBlocks: 120000,
       skipDryRun: true,
       from: '0x0B88418E95fb05d742E526E869ee2404d7904F81',
     },
     bsc: {
       provider: () => new HDWalletProvider(mnemonic, `https://bsc-dataseed1.binance.org`),
       network_id: 56,
       timeoutBlocks: 200,
       skipDryRun: true
     },
   },
 
   // Set default mocha options here, use special reporters etc.
   mocha: {
     timeout: 1200000
   },
 
   plugins: [
     'truffle-plugin-verify'
   ],
   
   api_keys: {
      ftmscan: 'K9GKU27P3DAG7N49AW9562FZ29PKRB7MFW',
     etherscan: 'NPIT4183DK8BMGVZDT9C4R14S1QMEHIT88',
     // etherscan: 'A2HNWK3VKZNQFAGU254HW1DAG4RPB8FI8T',
     bscscan: 'A2HNWK3VKZNQFAGU254HW1DAG4RPB8FI8T'
   },
 
   // Configure your compilers
   compilers: {
     solc: {
       version: "0.7.6",    // Fetch exact version from solc-bin (default: truffle's version)
       settings: {          // See the solidity docs for advice about optimization and evmVersion
        optimizer: {
          enabled: true,
          runs: 200
        },
        // evmVersion: "istanbul"
       }
     }
   },
 
   // Truffle DB is currently disabled by default; to enable it, change enabled: false to enabled: true
   //
   // Note: if you migrated your contracts prior to enabling this field in your Truffle project and want
   // those previously migrated contracts available in the .db directory, you will need to run the following:
   // $ truffle migrate --reset --compile-all
 
   db: {
     enabled: false
   }
 };
 