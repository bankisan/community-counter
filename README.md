# Community Counter

```
    COMMUNITY COUNTER               +                   
                                   / \
 _____        _____     __________/ o \/\_________      _________
|o o o|_______|    |___|               | | # # #  |____|o o o o  | /\
|o o o|  * * *|: ::|. .|               |o| # # #  |. . |o o o o  |//\\
|o o o|* * *  |::  |. .| []  []  []  []|o| # # #  |. . |o o o o  |((|))
|o o o|**  ** |:  :|. .| []  []  []    |o| # # #  |. . |o o o o  |((|))
|_[]__|__[]___|_||_|__<|____________;;_|_|___/\___|_.|_|____[]___|  |
```

`CommunityCounter` is a reaction to other counter contracts that enforce strict rules on _who_ has permission to modify a global counter. The crypto space tenets are based on sovereignty, privacy, and community. Instead, many in our industry are losing the plot and are building systems that are becoming centralized, permissioned, and controlled by the few.

Thankfully, there are those of us who will fight to keep the original promises alive. `CommunityCounter` is one of those projects. A public good that provides a global counter that **anyone** can increment. The gas costs are socialized and individuals do **not** need to expose their underlying wallet to modify the counter: they can do so anonymously if they wish.


## How to use

Using [ERC-4337](https://eips.ethereum.org/EIPS/eip-4337), users do not need to sign a transaction to modify the counter. Instead users can send a `UserOperation` (an ERC-4337 transaction) with the `increment` or `decrement` method as the `callData` value. As long as the community has funded the `CommunityContract` with enough ETH to cover the costs, then the counter will be updated. No metadata about the user who sent the `UserOperation` will be exposed publicly.

To keep the contract topped up with enough ETH, community members can call the `depositTo()` method on the `EntryPoint` contract. Users who wish to top up can send a transaction directly (using their wallet), or fund a wallet privately to send the deposit transaction. By topping up the contract, you are helping to ensure that the counter stays private and free for members who might need it.

## Deployed Contracts

| Network | CommunityCounter | EntryPoint |
| --- | --- | --- |
| Goerli | [0xD8B2D3ac1326Ee9A43C99884D1Ba569900BcA7eD](https://goerli.etherscan.io/address/0xD8B2D3ac1326Ee9A43C99884D1Ba569900BcA7eD) | [0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789](https://goerli.etherscan.io/address/0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789) |

## Acknowledgements

- [jtriley](https://github.com/jtriley-eth) for [`SafeCounter`](https://github.com/jtriley-eth/safe-counter), the permissioned counter.
- [horsefacts](https://github.com/horsefacts) for the [`Decentralized Summation System`](https://github.com/counterdao/dss) counter dao.

and [asciiart.eu](https://www.asciiart.eu/buildings-and-places) for the ascii header.
