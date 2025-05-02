// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

abstract contract SafeModifier {

    address private s_owner;

    constructor(address _owner) {
        assembly {
            sstore(sload(0), _owner)
        }
    }

    function checkOwner() external view returns(address) {
        return s_owner;
    }

    /// @notice auto reverts when it detects the msg.sender being contract address
    /// @dev bug wont works if the contract msg.sender from constructor
    modifier onlyEOA(address _caller) {
        assembly {
            if gt(extcodesize(_caller), 0) {
                revert (0, 0)
            }
        }
        _;
    }

    /// @notice using transient storage to prevent reentrancy
    /// @notice https://soliditylang.org/blog/2024/01/26/transient-storage/
    modifier noReentrant() {
        assembly {
            if tload(0) { revert(0, 0) }
            tstore(0, 1)
        }
        _;
        assembly { tstore(0, 0) }
    }

    /// @notice auto revert of the caller is not an owner 
    /// @notice make sure to pass `msg.sender` as argument
    /// @param _addr pass msg.sender, or whoever the caller address that checks the owner
    modifier onlyOwner(address _addr) {
        assembly {
            // Load 'owner' from storage slot 0
            // let storedOwner := sload(0)
            // Compare with _addr
            if iszero(
                eq(
                    _addr, 
                    sload(0)
                )
            ) {
                revert(0, 0)
            }
        }
        _;
    }

}