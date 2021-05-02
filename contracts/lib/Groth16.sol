// SPDX-License-Identifier: MIT
pragma solidity ^0.7.3;

import "./Pairing.sol";

library Groth16 {
    using Pairing for *;
    uint256 constant snark_scalar_field = 21888242871839275222246405745257275088548364400416034343698204186575808495617;

    struct VerifyingKey {
        Pairing.G1Point alfa1;
        Pairing.G2Point beta2;
        Pairing.G2Point gamma2;
        Pairing.G2Point delta2;
        Pairing.G1Point[] IC;
    }
    struct Proof {
        Pairing.G1Point A;
        Pairing.G2Point B;
        Pairing.G1Point C;
    }

    function verify(uint[] memory input, Proof memory proof, VerifyingKey memory vk) internal view returns (bool) {
        require(input.length + 1 == vk.IC.length,"bad input");
        // Compute the linear combination vk_x
        Pairing.G1Point memory vk_x = Pairing.G1Point(0, 0);
        for (uint i = 0; i < input.length; i++) {
            require(input[i] < snark_scalar_field,"input is out of field");
            vk_x = Pairing.addition(vk_x, Pairing.scalar_mul(vk.IC[i + 1], input[i]));
        }
        vk_x = Pairing.addition(vk_x, vk.IC[0]);
        
        return Pairing.pairingProd4(
            Pairing.negate(proof.A), proof.B,
            vk.alfa1, vk.beta2,
            vk_x, vk.gamma2,
            proof.C, vk.delta2
        );
    }

    function reduce(uint256 x) internal pure returns(uint256) {
        return x%snark_scalar_field;
    }

}
