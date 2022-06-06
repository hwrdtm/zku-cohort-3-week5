# Part 1 - Scalability

## Part 1.1

The scalability trilemma describes that there are three properties that a blockchain try to have but only two are generally achievable with various engineering architectures. The three properties are the following:

- Scalability: the blockchain can process more transactions than a single regular node can verify.
- Decentralization: the blockchain can run without any trust dependencies on a small group of large centralized actors.
- Security: the blockchain can resist a large percentage of participating nodes trying to attack it.

Traditional blockchains like pre-PoS Ethereum are decentralized, secure but not scalable. This is because every full node is required to verify every single transaction in each block. I am going to explore Sharding and Rollups as two blockchain scaling solutions and compare their implementations and trade-offs.

### Scaling Solution #1 - Sharding

Sharding is an on-chain scaling solution that is believed to achieve **all three properties** of the scalability trilemma - natively in the base layer - and is currently being explored + developed by the Ethereum developers. The general idea is to reduce the number of transactions that each node has to validate, thereby making the overall validation process faster, or that _more transactions can be validated given the same amount of computational power_.

With traditional blockchains, validators need to store and run computation for data across the entire chain. Conversely, with shard chains validators only need to store and run computation for data within the particular shard they are validating. Previously, given a 100 blocks, all full nodes would have to validate all 100 blocks. With a sharded architecture and, say, 100000 validators, we can imagine designating 100 validator nodes per each of the 100 validator committees, meaning each committee would only be tasked with validating **a single block**. Further optimizations can be achieved through using BLS signature aggregation to reduce the "chattiness" (overall number of network calls) of the network in order to achieve consensus. This drastically reduce the work needed per node not only from a computation standpoint but also from a consensus standpoint as each block is only propagated against each "subnet" / committee instead of the entire network of nodes. Additionally, it also encourages greater decentralization as hardware requirements to run a node are reduced, hence also improving security of the chain against 51% attacks. Although, this last part is true if only the attackers are not able to perform a 51% attack on a single shard. To achieve this, one technique is to use random sampling for the validator committee for each shard, and introducing a minimum number of validators per each committee. These two rules together make it statistically impossible for an attacker with less than 30% of the overall stake to successfully execute a 51% attack against any one shard.

In order to enhance security, there is ongoing research into how sharding can be implemented without needing 51% honest majority assumptions in the network at all, which can be broken down into two main problems:

1. Validating computation: checking that some computation was done correctly. This is necessary to ensure the new state root hash is valid given the set of computations and new state.
2. Validating data availability: checking that the inputs to some computation are stored in a way that can be downloaded, and performed without actually downloading the entire set of data for each block. This is necessary to ensure that the blockchain can continue to grow as newer computations are applied to existing state, which is available for users to download.

For the first problem, fraud proofs and zk-SNARKs can be used. Fraud proofs are essentially merkle proofs that prove the committed state root hash is different than what it should be. zk-SNARKs are cryptographic, validity proofs that aim to perform computation within arithmetic circuits in order to generate a proof for copmutational correctness.

For the second problem, a technique called data availability sampling can be used. This technique effectively uses erasure coding, zk-SNARKs for correctness, or alternatively, uses Polynomial Commitments (what is used by Ethereum developers for the sharding implementation) to do all of the above in a single component. The general idea is that, if less than 50% of a block's data is available, at least one data availability sample check will almost certainly fail for each client, causing the client to reject the block; if at least 50% of a block's data is available, then actually the entire block is available, because it takes only a single honest node to reconstruct the rest of the block.

Altogether, a sharded architecture enables greater throughput while maintaining as close security guarantees as the non-sharded architecture.

There are some notable trade-offs than with the traditional non-sharded architecture:

- Sharded chains that rely on committees and similar honest majority assumptions have weak accountability against adversaries. If an adversary breaks a single committee in a single shard, only a few of the nodes can be identified to have participated in the attack (in either case of 51% attack or presence of an adaptive adversary), and hence only a small amount of the adversary's stake can be slashed.
- Data availability sampling technique's security relies on a minimum number of online clients **that collectively make enough data availability sampling requests such that the responses almost always overlap to comprise at least 50% of the block**. This is necessary to provide the guarantee + conveniencve that each node only need to individually sample significantly less than 50% (read: <10%) in order to contribute to the overall data availability validation. This is regarded as a few-of-N trust model which does not allow for an entirely trustless system.
- Fraud proofs (if used) make for a generally worse user experience. This is because fraud proofs relies on timing assumptions as they generally work with a challenge period, a time window where merkle proofs can be submitted to prove the incorrectness of a committed state root hash. Even though the length of the challenge period could be a user-set parameter, the user experience is still not as fast as alternative methods, say using SNARK-based validity proofs instead.

References:

- https://vitalik.ca/general/2021/04/07/sharding.html
- https://ethereum.org/en/upgrades/shard-chains/
- https://blog.ethereum.org/2020/03/27/sharding-consensus/

### Scaling Solution #2 - Rollups

Rollups are an off-chain scalability solution that work by performing computation on transactions in batches before "rolling them up" into a single transaction that is later then committed onto the base layer 1 (Mainnet) chain.

There are two main variations of rollup solutions that are currently being explored - optimistic and ZK rollups:

- Optimistic rollups: assume transactions are valid by default and **only runs computation, via a fraud proof, in the event of a challenge** during the challenge window (for Optimism this is ~1 week). The challenge period is a time window during which anyone can dispute the legitimacy of the data contained in a batch. Disputes are executed via fraud proofs, which consists of providing a merkle proof and also the batch data, and then comparing the state root hashes with the proposed state root hash that is about to be committed to the base chain.
- ZK rollups: runs computation off-chain within arithmetic circuits of the zk-SNARK proving schemes, and submits a validity proof to the base layer along with the batch.

References:

- https://ethereum.org/en/developers/docs/scaling/

### Comparing Sharding vs. Rollups

Here we compare the two scaling techniques across a number of factors.

#### UX

Let's cover 1) time to finality and 2) withdrawal periods as part of the overall UX of using these scaling solutions.

Time to finality when interacting with rollups is going to be orders of magnitude faster than interacting with a sharded base layer chain.

Withdrawal periods are only relevant to rollups since they rely on withdrawal periods to maintain security of transactions. However, between rollup solutions there can still be drastically different time requirements. For example, optimistic rollups have a 1 week challenge period for fraud proofs to be submitted, where as withdrawals with ZK rollups are valid as soon as the next batch is submitted (because this means the previous batch's state root + validity proof was committed and accepted by the base layer).

Overall, the UX of dApps should be better when interacting with rollups as opposed to the sharded base chain, since the majority of the interactions will be **within a layer**, and withdrawals are assumed to be an occasional necessity.

#### Complexity of Technology

A sharded base chain can rely on various measures for security. If relying purely on random sampling for committees for consensus, then this is relatively simple technology. If the sharded base chain were to adopt fraud proofs or validity proofs via zk-SNARKs, then these proving technologies would be quite similar to that used by optimistic and ZK rollups respectively. Fraud proofs are essentially merkle proofs made during a challenge period that show that the committed state root hash of some batch is incorrect and are relatively straightforward technology. On the otherhand, zk-SNARKs require non-trivial amounts of knowledge in cryptography, mathematics and programming to understand well, which is why this technology still remains to be relatively unknown to the larger community of developers and enthusiasts in the crypto space.

#### Generalizability

Interacting with a sharded base chain is going to be no different than interacting with the Ethereum network as it is today and general purpose applications will be supported against the EVM.

Across rollups, there is a varying degree of EVM compatibility. Optimistic rollups have general purpose EVMs, whereas ZK rollups like zkSync are still working on a zkEVM which is supposed to be (mostly) EVM compatible.

#### Computation Costs

Computations made directly with a sharded base chain is still going to be orders of magnitude more costly that interacting with layer-2 rollups. However, there is a slight variation in costs across rollups. For example, optimistic rollups are going to be cheaper than ZK rollups as it is many times more expensive to perform the same computation within the arithmetic circuits for generating zk-SNARK proofs.

#### Security

Rollups are built as a layer-2 solution on top of the existing layer-1 Mainnet chain and mostly seek to move the transaction computation off-chain. Since consensus of both 1) valid computation and 2) valid data availability is still performed in the layer-1 base chain, rollups are often said to "derive" their security from the base chain. In other words, sharding and rollups have **the same security** since rollup's security is derived from the sharded chain's security.

## Part 1.2

### zkSync

zkSync is a ZK rollup solution. It works by using cryptographic, validity proofs generated by performing computation within arithmetic circuits as part of a zk-SNARK proving scheme. Every batch of rolled-up transactions is committed with its corresponding validity proof onto the base layer chain.

zkSync 2.0 offers layer-2 state to be divided in 2-sides:

- zkRollup with on-chain (layer-1) data availability
- zkPorter with off-chain (layer-2) data availability

zkPorter is claimed to be able to support 10k-20k TPS (transactions per second), and zkSync around 3k TPS. zkPorter is an account-based scaling protocol that uses a sharded architecture to tackle the data availability problem. Instead of relying on the layer-1 for data availability guarantees, zkPorter shards can implement their own consensus mechanisms for validating data availability. Beyond shard 0 (since shard 0 is just zkRollup which relies on base chain for data availability guarantees), shard 1 is secured via cryptoeconomic incentives via Guardians (staked holders) and will implement a form of Proof of Stake consensus mechanism. zkPorter supports an arbitrary amount of shards and zkSync's approach greatly encourages decentralization by having each shard run whichever protocol they wish to validate data availability. zkPorter is secure since Guardians are unable to steal funds - they can only freeze the zkPorter state.

zkPorter is similar to StarkEx's Validium, but zkSync focus more on decentralization.

References:

- https://blog.matter-labs.io/zkporter-a-breakthrough-in-l2-scaling-ed5e48842fbf
- https://blog.matter-labs.io/zkporter-composable-scalability-in-l2-beyond-zkrollup-2a30c4d69a75

### StarkNet

StarkNet is another layer-2 ZK rollup solution that uses zk-STARK proving schemes to generate validity proofs. StarkEx is a permissioned tailor-made scaling engine, designed by StarkWare to fit the specific needs of apps.

There are several data availability modes for users to choose from when using StarkEx:

- Rollup mode: data is published on-chain.
- Validium: data is stored off-chain. Users must trust an Operator to properly manage and store their data. An Operator is chosen from a Data Availability Committee, which is assembled from reputable bodies such as ConsenSys, Infura, Nethermind, StarkWare etc. dApps can easily remove or add committe members.
- Volition: data can be customized to be stored on- or off- chain on a per transaction basis.

References:

- https://starkware.co/starknet/
- https://docs.ethhub.io/ethereum-roadmap/layer-2-scaling/zk-starks/
- https://consensys.net/blog/blockchain-explained/zero-knowledge-proofs-starks-vs-snarks/

### Comparing zkSync and StarkNet

Below we compare zkSync and StarkNet across factors where they differ in an attempt to understand which project is more likely to come out on top in the long term.

#### Quantum Resistance / Security

STARKs are post-quantum secure as they only rely on the existence of a cryptographic hash function, which is a well-explored and time-tested assumption. SNARKs rely on much newer (mathematical) theories that have yet to be proven in many aspects.

#### Verification Cost on L1

The cost of verifying validity proofs for zkSync is around 600k gas, compared to around 2000k-5000k gas for a STARK-based solution like StarkNet. This is roughly correlated with the larger proof sizes with STARK-based proving schemes as opposed to SNARK-based ones.

#### Decentralization

zkPorter is more decentralized than Validium as an approach towards off-chain data storage since zkPorter supports an arbitrary amount of shards, each of which can implement its own consensus algorithm for validating data availability as it wishes. This is in contrast to the high degree of centralization with the Data Availability Committee that facilitate all transactions going through StarkEx in Validium mode.

#### EVM Compatibility

zkSync is supposedly (mostly) EVM compatible with the development of zkEVM. This means that (most of the time) developers can take the same exact bytecode that is deployed onto the Ethereum base chain and deploy it directly onto the zkSync layer-2 system, without writing a single line of code.

In contrast, StarkNet is entirely EVM **incompatible**. While there is current work in developing [Warp](https://github.com/NethermindEth/warp) - a transpiler that transpiles Solidity smart contracts into Cairo, StarkNet's smart contract programming language - currently it is impossible for developers to deploy Solidity smart contracts directly onto StarkNet's VM.

#### Who Will Prevail?

In my opinion, zkSync will come out on top as the more successful scaling solution. With its cheap(er) verification costs, EVM compatibility and its imminent ship date (summer 2022?) it will be able to grow network effects sooner than StarkEx and these are the more important factors than, say, its lack of post-quantum security. And once zkSync emerges as the "killer layer-2 infrastructure", it will become hard for the network effects to stray away into other systems like StarkNet.

# Part 2 - Interoperability

## Part 2.1

Bridges enable the cross-chain transfer of assets and information. There are trust-based and trustless bridges - trust-based bridges rely on centralized operators to bridge funds across chains, whereas trustless bridges rely on the cryptoeconomic security of the underlying infrastructure to secure and bridge the funds.

Taking ERC20 token transfers as an example, here is a step-by-step breakdown of what happens when these assets are bridged between EVM compatible chains. Given a User holding Tokens who wishes to bridge Tokens from a From chain to a To chain:

1. User sends Tokens to a bridge contract that lives on the From chain. The Tokens are locked in that bridge contract.
2. Bridge contract on From chain "sends signal" to bridge contract on To chain to mint the same amount of Tokens on the To chain.
3. Bridge contract on To chain sends Tokens to User account on the To chain.

When the user decides to bridge Tokens back from the To chain to the From chain, a similar process occurs except the Tokens on the To chain are burnt before they get released to the user from their locked state in the bridge contract on the From chain.

From this breakdown, we can see that the following components are necessary to build a token bridge application:

- Bridge smart contracts: we need smart contracts to exist on both chains to manage the locking / burning of the Tokens on the From / To chain respectively, upon receiving Tokens sent by the user.
- Web frontend: we need a web application for users to interact with for knowing where to send their Tokens to when bridging to and from the chains.
- Backend process: we need a long-running process to listen to tokens being received in the bridge wallet contract on one side of the bridge before "sending a signal" to the other chain to send Tokens to the user. "Sending a signal" really just means that this process calls a particular smart contract function to release locked funds / mint new Tokens to the user's wallet.

References:

- https://chainstack.com/how-to-create-blockchain-bridge/
- https://blog.connext.network/the-interoperability-trilemma-657c2cf69f17
- https://www.youtube.com/watch?v=8Te5TkcYi54&t=36s

## Part 2.2

AZTEC uses a UTXO model similar to Bitcoin, as opposed to an account-based model. UTXO stands for Unspent Transaction Output, and each wallet can have multiple transaction output "belonging" to it, that it has authority over spending it, since it is "unspent". Imagine Alice having two outputs, 10 BTC and 30 BTC. If she wishes to spend 35 BTC, she would spend, say, the entire 30 BTC UTXO and also half of the 10 BTC UTXO.

An AZTEC note can be thought of as an UTXO, and a wallet can have multiple (unspent) AZTEC notes. State of notes are managed by the specific Note Registry of the underlying public token - ETH as an ERC20 would have its own Note Registry, and so would BTC. Since every confidential transaction within the AZTEC protocol would result in the destruction and creation of notes, each transaction would be interacting with the note registry corresponding to the underlying public token.

Note ownership is implicit via its corresponding signature, signed by the note's owner.

Specifically, an AZTEC note contains the following information:

- Publicly,
  - An AZTEC commitment which is essentially an encrypted representation of how much value the note holds
  - An Ethereum address of the note's owner
- Privately,
  - The value of the note
  - The note's viewing key, which allows whomever in possession of it to decrypt the note, but not spend it.

Most of the confidential transactions are performed in a join-split style, where zero-knowledge proofs are generated to prove that the value of the input notes are equal to the value of the output notes of a transaction. This join-split concept is what facilitates token transfers between AZTEC notes for the same type of underlying token, say, ETH to ETH. Additionally, join-split proofs are used when value is entering or existing the AZTEC protocol / ecosystem, ie. when the public ERC20 token is converted into AZTEC notes and vice versa. The difference in these cases is determined by the public AZTEC commitment values.

References:

- https://aztec-protocol.gitbook.io/aztec-documentation/guides/an-introduction-to-aztec
- https://aztec-protocol.gitbook.io/aztec-documentation/guides/an-introduction-to-aztec/confidential-transactions-have-arrived

# Part 3 - Final Project: **Anonymous Coordinape**

Coordinape is a peer-based payroll management tool for DAOs. It features a Map functionality which allows anyone to visualize each contributor's public allocations of GIVE tokens towards the other contributors. This is rather sensitive information to many, and it would be nice if this can be kept private. Organizational peer-reviews make sense to be kept private - now, why aren't peer-based payroll allocations too?

With **Anonymous Coordinape**, Circle members submit their GIVE token allocations to the rest of the team **privately**. The only time when the GIVE tokens are made public is **after** each of the Circle members' private token allocations are aggregated.

Here is an example:

1. There exists a Circle with Alice, Bob and Charlie. Total GIVE tokens possible within Circle is 300 (100 GIVE tokens allocated to each member initially.)
2. Once an Epoch begins, Circle members submit their distributions privately:

   - Alice -> Bob: 30 GIVE
   - Alice -> Charlie: 70 GIVE
   - Bob -> Alice: 40 GIVE
   - Bob -> Charlie: 60 GIVE
   - Charlie -> Alice: 10 GIVE
   - Charlie -> Bob: 10 GIVE

3. Once the Epoch ends, the token distributions are aggregated, summed, and the following is made public:

   - Alice receives: 50 GIVE
   - Bob receives: 40 GIVE
   - Charlie receives: 130 GIVE

4. The GIVE tokens are automatically converted into GET tokens.
5. Each Circle member then proceeds to redeem USDC from GET tokens **within a claim window**.

Read the Competitive Landscape section below for more details on the Coordinape product.

## Functional Requirements

Here is the basic functionality for the MVP:

1. As an admin, I can create a Coordinape Circle.
2. As an admin of my Circle, I can add members to my Circle.
3. As an admin of my Circle, I can set the time window for a new Epoch.
4. As an admin of my Circle, all my Circle's members are automatically part of the new Epoch. (this is for simplicity - in the future we can add members to each Epoch)
5. As a member of a live Epoch, I am automatically given 100 GIVE tokens.
6. As a member of a live Epoch, I can submit my private distribution commitment along with a ZK proof.
7. As a member of an expired Epoch, I can publicly see the amount of GIVE / GET tokens I have been allocated by team members.
8. As a member of an expired Epoch, any of my GIVE tokens that are unallocated are burned.

## Out of Scope

**Anonymous Coordinape** develops a solution for anonymous token distributions (or voting, essentially). The following concepts are considered out of scope for this proof-of-concept.

### Anonymous Payroll

We do not explore how ZK technology can be used to preserve the privacy of wallets, how many funds are going into each address and identity (eg. which humans are connected to which wallets.)

## Proposal Overview

Here is an overview of the components that are needed to build this product:

1. ERC20 Smart Contract for GIVE
2. Web frontend
3. Circom circuit
4. Smart Contract for Contributor, Circle, GIVE token management.
5. Smart Contract for verifying ZK proofs.
6. Backend process(es)

In detail, this is how the system would work:

1. An ERC20 smart contract will need to be deployed to manage ownership of the GIVE tokens.
2. A web frontend would manage user interactions with the dApp as well as generating a zk-SNARK based proof that the user did submit a valid distribution of their GIVE tokens. At the same time, their private token distributions are sent over the network to a long-running process managed by the developers (ie. myself, hosted in some cloud provider).
3. An arithmetic circuit will need to be constructed to prove that users' private token allocation to the rest of the contributing team is valid without revealing it.
4. A smart contract is needed to manage the state of contributors, Circles, and trigger GIVE / GET token transfers and USDC redemption.
5. A smart contract is needed to verify ZK proofs.
6. A backend process is needed to calculate the final GIVE token distributions that will be revealed at the end of each Epoch, then committed on-chain for users to then convert into GET before redeeming into USDC.

TODO: Flow + Architecture diagram to come in the future.

### Circuit Design

Here is the specification for the arithmetic circuit:

- **Private** inputs:
  - An array of integers representing the list of **all** Circle members, ordered lexicographically. The 0-th index will represent the number of tokens that are **not** allocated to any contributor.
  - Salt
- Checks / Constraints:
  - Each integer in the array is greater than 0.
  - Sum of integer array is equal to the total GIVE tokens to allocate, which is 10000 (to work nicely with basis points, or hundredths of a percentage)
- **Public** outputs:
  - Hash of the integer array along with a salt.

A salt is needed to prevent brute-force attacks. In most cases, Coordinape Circles will be small (as they should be) which reduces the search space for an attacker to find out a pre-image corresponding to the hash that is committed onto the public smart contract. A privately generated salt will drastically increase the search space to make it programmatically and statistically impossible for an attacker to find a collision.

Please check `poc_circuit.circom` in this directory for a POC for what the arithmetic circuit might look like. (incomplete due to lack of time)

## Use Cases

Anonymous Coordinape can be used just like Coordinape in any organizational process where a set of contributors need to be compensated, **with the additional benefit that token allocations are kept private, but provably valid**.

## Competitive Landscape

In this section we explore some competitor products and compare the advantages / disadvantages Anonymous Coordinape has

### Competitor #1: Coordinape

Coordinape is a peer-based payroll management tool for DAOs. Traditionally, a top-down approach is often used to assess the quality of DAO member contributions, which is time-consuming as higher level "managers" will need to spend time to switch into the contexts of the implementers. What is worse is that they may spend the time and end up with an assessment of the quality **that is misaligned with other team members** - think about the time when your manager is not aware of certain contributions you make to your wider team. This misalignment is exacerbated with more levels of hierarchy as generally seen in larger organizations.

Much like how companies have peer-reviews that help drive promotion / salary-raise / code-merge processes, Coordinape presents an alternative to payroll management where a bottom-up approach is used to identify where the most value and impact originated from.

Main flow:

- Admins create a Circle and add contributors to this Circle. A Circle is simply a collection of members most intuitively grouped by specialization - for example, there can be a Development Circle grouping all the software developers together.
- Admins create a new Epoch. An Epoch is simply a certain time period, and can be mapped to a SCRUM-style sprint, for those who are familiar. Each contributing member provides a description per Epoch describing what they've been working on during the current Epoch.
- Once an Epoch begins, each contributor receives a fixed amount of GIVE tokens (eg. capped at 100) and can decide for themselves how to distribute these GIVE tokens to the rest of the contributing team members.
- Once an Epoch ends, each contributor's GIVE tokens are converted into GET tokens, which are redeemable for USDC. Any uspent GIVE tokens are burnt.

Here's an example (courtesy of [this](https://www.daomasters.xyz/tools/coordinape#:~:text=How%20does%20it%20work%3F,by%20specialization%2C%20e.g.%20development.)):

- Sophie receives 50 GIVE tokens from the community for her contributions.
- At the end of the Epoch, her GIVE tokens are automatically converted to GET tokens.
- The total allocation across the whole DAO during this Epoch is 1,000 GET tokens.
- The DAO decides that their total budget for this Epoch is 25,000 USDC.
- Sophie’s 50 GET Tokens are 5% of the available 1,000 GET tokens, so she is sent 5% of the DAO’s total budget (1,250 USDC.)

References:

- [How does it work](https://www.daomasters.xyz/tools/coordinape#:~:text=How%20does%20it%20work%3F,by%20specialization%2C%20e.g.%20development.)
- [Demo](https://www.youtube.com/watch?v=J8oGun8EKDE)

### Competitor #2: Utopia

Utopia is a payroll management tool for DAOs.

Main flows:

- Admins add recipients to be paid.
- Create one-off payment requests.
- Create recurring payments requests
- Batch payment requests into single transactions.
- Gasless transactions (after number of Admin signatures > multisig threshold)

### Comparison

Comparing Anonymous Coordinape with Utopia is much like comparing Coordinape with Utopia - much of it is [covered here anyways](https://www.daomasters.xyz/tools/coordinape#:~:text=How%20does%20it%20work%3F,by%20specialization%2C%20e.g.%20development.).

The more interesting comparisons are between Anonymous Coordinape and the original Coordinape:

- Advantages:
  - Privatised peer-review, effectively. As a contributor, you know how your peers view you overall, but you can't reverse engineer to the extent which contributor decided to pay you how much.
  - More aspects of the overall UX are placed on-chain.
- Disadvantages:
  - Complicated product means harder to maintain software, debug problems.
  - As more aspects are moved on-chain, this will lead to worse UX as users may have to sign more messages (not necessary pay more out of pocket)
  - Reliance on centralized actor (though there are active plans to move away from them, this is just for MVP.)

## Proposal Ask

Anonymous Coordinape will become community-driven and self-funded by its own DAO. In order to get this up and running, I am requesting the $15k/year stable basic income to take care of initial development, welfare, and operations costs. This is based on the [5 milestones introduced via the zkDAO Launch Grant Program](https://talk.harmony.one/t/about-the-zkdao-category/13475).

## Roadmap

| Milestone | Date       | Deliverable(s)                                      |
| --------- | ---------- | --------------------------------------------------- |
| 1         | Wed Jun 8  | Architecture diagram, flow diagram                  |
| 2         | Thu Jun 9  | Circom circuit, all smart contracts including ERC20 |
| 3         | Mon Jun 13 | Backend process, web frontend scaffold              |
| 4         | Mon Jun 20 | Web frontend, overall code completion.              |

Aim for code complete by June 20. QA from June 20-27.

## FAQ

- Why are we not building this on top of Semaphore?
  - The aspect of Coordinape that we're improving with Anonymous Coordinape can be seen as a form of ZK voting, and Semaphore has been used for several voting applications previously. To recap, Semaphore is great for 1) basic membership validity checks and 2) enforcing one-time signals per each external nullifier. In our case, it wouldn't make sense to hide the public keys that are associated with a Circle (as it is trivial to trace who redeemed USDC with GET tokens anyways), and we should allow users to send as many updates to their token allocation commitments as they wish while the Epoch is still live.
- Why does this need to be on the blockchain / use smart contract anyways if centralized actors have full knowledge of everyone's token distributions anyway?
  - The implementation behind this MVP can be seen as a first step before we adopt homomorphic encryption techniques to **remove dependence on centralized actors (and anyone else ever seeing the private token allocations)** down the line. This is a known **next step**.

## Open Questions

The following questions will be answered in the future:

- How can we strip more scope off of this MVP?
- Can any component be designed to be re-usable?
- Can we consider making the admin's budget per Epoch private too? That way, contributors detach from the actual monetary amount when giving out GIVE tokens.
- This current proposal faces the same problem of relying on centralized actors for processing blind auctions and sending funds to the actual winner in [ZK Blind Auction](https://github.com/heivenn/zk-blind-auction). Would it be possible to adopt Homomorphic Encryption techniques to avoid the need for centralized actors altogether?
