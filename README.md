# Constellation 2023 Hackathon Submission
Secure On-chain Oracle is a blockchain oracle that offers secure price feeds for emerging, low-liquidity, or even low trust assets, allowing protocols to develop financial products utilizing these assets, e.g. lending protocols.

## Price Oracle Manipulation Impedes Mainstream Adoption
There are two major classes of price oracle manipulation: 1) flashloan manipulation, which is instantaneous and essentially risk-free, and 2) pool ratio manipulation, which occurs over multiple transactions and potentially multiple blocks, and it carries risk because the attacker may leak capital to arbitrageurs who have the opportunity to profit from the liquidity manipulation.

Flashloan manipulation is a technique whereby an attacker acquires a large sum of assets in a flashloan, for the duration of a single transaction, and where they combine borrowing assets using the flashloan'd funds as collateral with manipulating the price of the asset borrowed, allowing them to borrow more assets as the price of their collateral artifically rises (and increases their ability to borrow more funds). Pool ratio manipulation works in a similar way, except an attacker provides the capital themselves, it's not instantaneous, and their manipulation exposes them to the risk of sellers dumping the price down against their position.

In either case, the result of an exploit that uses price oracle manipulation is that a lending protocol becomes insolvent, such that it cannot pay back its lenders, because the value of the collateral used to borrow and withdraw assets from the protocol was artificially inflated, and once the price manipulation event ends, there isn't enough collateral to recover the borrowed assets. Hundreds of millions of dollars have been stolen using these techniques, undermining the security, utility, and mainstream adoption of decentralized finance.

### Examples
1. Flashloan Manipulation:
    - [Platypus Finance](https://rekt.news/platypus-rekt2/)
2. Flat-out Price Manipulation:
    - [Moola Markets](https://rekt.news/moola-markets-rekt/)


## Verimedian: A Highly Scalable, Trust-minimized, and Permissionless Solution
Verimedian is a verifiable median; it is the median of a list of values that is *provable* using zero knowledge proofs. Our proof of concept uses circom and rapidsnark to compute the proofs.

### The Year of Matrix Multiplication
[According to wikipedia](https://en.wikipedia.org/wiki/Median), "In statistics and probability theory, the median is the value separating the higher half from the lower half of a data sample, a population, or a probability distribution. For a data set, it may be thought of as 'the middle' value."

Our solution is possible by invoking linear algebra to define the median of an array. Consider an unsorted array $$X$$ to be a vector in $$R^n$$, where $$n = 2i +1$$ is an odd integer, and similarly, consider $$X' = \text{sorted}(X)$$ to be a vector in the same space. That is, $$X'$$ is a permutation of the vector $$X$$ such that its values are ordered from least to greatest. Then there exists a square matrix $$M \in R^{n,n}$$ which represents the permutation transformation that takes the unsorted $$X$$ to the sorted $$X'$$. By this definition, $$X' = MX$$. Hence, the median is the "center" value of $$X'$$, because it is an odd length, sorted vector.

Our zero knowledge solution differs from the conventional approach to sorting an array in quadratic arithmetic programs. The conventional approach is to write a provable sorting algorithm, then to return the center value of the sorted array (in the case of an odd-length array), or to return the mean average of the middle-two values of the sorted array (in the case of an even-length array). For example, one might implement merge sort or quick sort in a zero knowledge proof. However, our solution uses linear algebra to define the sorted array, hence it is independent of any particular sorting algorithm.

## A Chainlink Solution
We use Chainlink Automation to record prices at a set interval, and we use a Chainlink External Adapter to compute the median of the recorded prices and a zero knowledge proof that the median is valid.

However, we plan to include Chainlink Functions in the final design.

[VerimedianSimple.sol#L77-L216](https://github.com/codename-mainstream-adoption/constellation/blob/main/smart_contracts/src/VerimedianSimple.sol#L77-L216)