pragma circom 2.0.0;

include "./node_modules/circomlib/circuits/comparators.circom";
include "./node_modules/circomlib/circuits/poseidon.circom";

template CheckTokenAllocations(n) {
    // Private inputs
    signal input tokenAllocations[n];
    signal input salt;

    // Output
    signal output tokenAllocationHash;

    // Check token allocation is positive
    component isAllocationPositive[n];


    for (var i = 0; i < n; i++) {
        isAllocationPositive[i] = GreaterEqThan(14);
    }

    for (var i = 0; i < n; i++) {
        isAllocationPositive[i][0] <== tokenAllocations[i];
        isAllocationPositive[i][1] <== 0;

        // TODO: we want to make sure all GreaterEqThan comparisons are TRUE, or output 1 flag.

    }

    // Check token allocation is valid - sums to 10000

    // TODO:

    // Compute Poseidon hash of token allocation

    // TODO:
}

