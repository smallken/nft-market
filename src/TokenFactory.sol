// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/proxy/Clones.sol";

contract TokenFactory {
    address public implementation;
    address[] public tokens;

    constructor(address _implementation) {
        implementation = _implementation;
    }

    function createToken() external returns (address) {
        address clone = Clones.clone(implementation);
        tokens.push(clone);
        return clone;
    }

    

    function createClone(address prototype) internal returns (address proxy) {
        bytes20 targetBytes = bytes20(prototype);
        assembly {
            let clone := mload(0x40)
            mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(clone, 0x14), targetBytes)
            mstore(
                add(clone, 0x28),
                0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000
            )
            proxy := create(0, clone, 0x37)
        }
        return proxy;
    }

    function getImplementation() external view returns (address) {
        return implementation;
    }
}
