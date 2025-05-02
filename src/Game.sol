// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {SafeModifier} from "./SafeModifier/SafeModifier.sol";

import {STKM} from "./factory/STKM.sol";
import {ISTKM} from "./Interface/ISTKM.sol";

contract Game is SafeModifier(msg.sender) {

    ISTKM private immutable I_STKM;  

    constructor(ISTKM _STKM) { I_STKM = _STKM; }

    /*//////////////////////////////////////////////////////////////
                                 ERC20
    //////////////////////////////////////////////////////////////*/

    function buySTKM() external payable onlyEOA(msg.sender) noReentrant {
        I_STKM.buySTKM(msg.sender, msg.value);
    }   

    function giveSTKM(address _to, uint256 _amount) external onlyOwner(msg.sender) {
        I_STKM.giveSTKM(_to, _amount);
    }

    function withdrawSTKM(uint256 _amount) external onlyEOA(msg.sender) noReentrant {
        I_STKM.withdrawSTKM(msg.sender, _amount);

        (bool ok, ) = msg.sender.call{value: _amount}("");
        require(ok, "Vault: burn transaction failed");
    }

    function updateInterest() external onlyEOA(msg.sender) noReentrant {
        I_STKM.updateInterest(msg.sender);
    }

    function balanceOf() external view returns (uint256) {
        return I_STKM.balanceOf(msg.sender);
    }

    function RewardsLatestUpdateTime() external view returns (uint256) {
        return I_STKM.checkInterestLastUpdate(msg.sender);
    }

    receive() external payable onlyEOA(msg.sender) noReentrant { }
    fallback() external payable onlyEOA(msg.sender) noReentrant { }

}