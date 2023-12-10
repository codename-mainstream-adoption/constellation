# Constellation 2023 Hackathon Submission
Secure On-chain Oracle is a blockchain oracle that offers secure price feeds for emerging, low-liquidity, or even low trust assets, allowing protocols to develop financial products utilizing these assets, e.g. lending protocols.

## Price Oracle Manipulation Impedes Mainstream Adoption
There are two major classes of price oracle manipulation: 1) flashloan manipulation, which is instantaneous and essentially risk-free, and 2) pool ratio manipulation, which occurs over multiple transactions and potentially multiple blocks, and it carries risk because the attacker may leak capital to arbitrageurs who have the opportunity to profit from the liquidity manipulation.

Flashloan manipulation is a technique whereby an attacker acquires a large sum of assets in a flashloan, for the duration of a single transaction, and where they combine borrowing assets using the flashloan'd funds as collateral with manipulating the price of their collateral, allowing them to borrow more assets as the price of their collateral artifically rises (and increases their ability to borrow more funds). Pool ratio manipulation works in a similar way, except an attacker provides the capital themselves, it's not instantaneous, and their manipulation exposes them to the risk of sellers dumping the price down against their position.

In either case, the result of an exploit that uses price oracle manipulation is that a lending protocol becomes insolvent, such that it cannot pay back its lenders, because the value of the collateral used to borrow and withdraw assets from the protocol was artificially inflated, and once the price manipulation event ends, there isn't enough collateral to recover the borrowed assets. Hundreds of millions of dollars have been stolen using these techniques, undermining the security, utility, and mainstream adoption of decentralized finance.

### Examples
1. Flashloan Manipulation:
    - [Platypus Finance](https://rekt.news/platypus-rekt2/)
2. Flat-out Price Manipulation:
    - [Moola Markets](https://rekt.news/moola-markets-rekt/)

## Verimedian: A Highly Scalable, Trust-minimized, and Permissionless Solution
Verimedian is a verifiable median; it is the median of a list of values that is *provable* using zero knowledge proofs.

### The Year of Matrix Multiplication
[According to wikipedia](https://en.wikipedia.org/wiki/Median), "In statistics and probability theory, the median is the value separating the higher half from the lower half of a data sample, a population, or a probability distribution. For a data set, it may be thought of as 'the middle' value."

Our solution is possible by invoking linear algebra to define the median of an array. Consider an unsorted array $X$ to be a vector in $R^n$, where $n = 2i +1$ is an odd integer, and similarly, consider $X' = \text{sorted}(X)$ to be a vector in the same space. That is, $X'$ is a permutation of the vector $X$ such that its values are ordered from least to greatest. Then there exists a square matrix $M \in R^{n,n}$ which represents the permutation transformation that takes the unsorted $X$ to the sorted $X'$. By this definition, $X' = MX$. Hence, the median is the "center" value of $X'$, because it is an odd length, sorted vector.

Our zero knowledge solution differs from the conventional approach to sorting an array in quadratic arithmetic programs. The conventional approach is to write a provable sorting algorithm, then to return the center value of the sorted array (in the case of an odd-length array), or to return the mean average of the middle-two values of the sorted array (in the case of an even-length array). For example, one might implement merge sort or quick sort in a zero knowledge proof. However, our solution uses linear algebra to define the sorted array, hence it is independent of any particular sorting algorithm.

## A Chainlink Solution
### Proof of Concept
We use Chainlink Automation to record prices at a set interval, and we extend a Chainlink node with a custom external adapter to compute the median of the recorded prices and a zero knowledge proof that the median is valid. The external adapter uses rapidsnark to compute proofs optimally fast. The average response time of the Chainlink node is ~4 seconds. Here are three transactions showing the request / response times of a Verimedian proof:

  1. [request](https://sepolia.arbiscan.io/tx/0x91edad394de7c13c61f5ef1e34fbaadc8c632e347c70263778c8a269525b699b) / [response](https://sepolia.arbiscan.io/tx/0x594d9681b745babdd3af40a6157d74545db846574e1561270cae177f463190ba) / 12:50:13 AM +UTC / 12:50:17 AM +UTC
  2. [request](https://sepolia.arbiscan.io/tx/0xcf9ca5573342709b7a670f66d4d678d77147a147565ffa356614c456bdcc666a) / [response](https://sepolia.arbiscan.io/tx/0x1816973691f871773310356557021dd56141d22abe35966bbde5e765b434b1e4) / 09:55:25 PM +UTC / 09:55:28 PM +UTC
  3. [request](https://sepolia.arbiscan.io/tx/0x8a69ef5e616ccb46d7b983819af322d2d30371d3176796c312e2e33d1dd956d6) / [response](https://sepolia.arbiscan.io/tx/0xc0d0e128a8ef918503b04888ca970a7379cbd70d1eb0d0d56f7615b16cdca238) / 08:24:45 PM +UTC / 08:24:51 PM +UTC

### Parameters of the Median
The prices are snapshotted 77 times a day, and each median is computed over a set of 77 prices. The latest price of the contract is a moving 24 hour median that can be updated every ~18 minutes. For an attacker to compromise the oracle, they would need to manipulate the price of the oracle for over half of the recorded values. In a 24 hour period, they would need to manipulate the price 39 times, which can be done by using flashloans, by purchasing/selling a given asset, or by using MEV to sandwich attack snapshot events.

There's tradeoffs to be made according to the number of values in a proof and the chosen interval period of snapshots, and this needs to be studied to construct a gradient of security vs cost vs freshness of price.

### Usage of Chainlink in our Solution
[VerimedianSimple.sol#L77-L216](https://github.com/codename-mainstream-adoption/constellation/blob/main/smart_contracts/src/VerimedianSimple.sol#L77-L216)

[Chainlink Automation App](https://automation.chain.link/arbitrum-sepolia/88085477303397698488464179626709927703473366835164810685580610177613864293133)