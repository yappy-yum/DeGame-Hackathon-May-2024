// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {ISTKM} from "../Interface/ISTKM.sol";

import {ERC20} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract STKM is ISTKM, ERC20("STICKMAN", "STKM"), Ownable(msg.sender) {

    mapping(address user => uint256 lastUpdate) private s_userLastUpdate; 

    /*//////////////////////////////////////////////////////////////
                              custom error
    //////////////////////////////////////////////////////////////*/

    error STKM__MintZero();
    error STKM__BurnZero();
    error STKM__ApprovingZero();
    error STKM__transferZero();
    error STKM__transferFailed();
    error STKM__transferFromFailed();

    /*//////////////////////////////////////////////////////////////
                                  mint
    //////////////////////////////////////////////////////////////*/     

    /**
     * @notice pay to get STKM (child contract will handle the payment)
     *
     */
    function buySTKM(address _to, uint _amount) external onlyOwner {
        if (_amount == 0) revert STKM__MintZero();

        _mint(_to, _amount);
        _mintUserAccruedRewards(_to);
    }

    /**
     * @notice this function is used to provide hard earned STKM to the user
     * @param _to user address
     * @param _amount amount of STKM to give
     *
     */
    function giveSTKM(address _to, uint256 _amount) external onlyOwner {
        if (_amount == 0) revert STKM__MintZero();

        _mint(_to, _amount);
        _mintUserAccruedRewards(_to);
    }

    /*//////////////////////////////////////////////////////////////
                                  burn
    //////////////////////////////////////////////////////////////*/  

    /**
     *
     * @notice burn STKM and convert to crypto coin
     * @param _amount token amount to be burnt
     *
     */
    function withdrawSTKM(address _user, uint256 _amount) external onlyOwner {
        if (_amount == 0) revert STKM__BurnZero();

        _mintUserAccruedRewards(_user);
        _burn(_user, _amount);
    }

    /*//////////////////////////////////////////////////////////////
                             transfer STKM
    //////////////////////////////////////////////////////////////*/    

    /**
     * @notice transfer `_amount` of STKM from msg.sender to address `_to`
     * @param _to user address to be transfered to
     * @param _amount amount of STKM to transfer
     *
     */
    function transfer(address _to, uint _amount) 
        public override(ISTKM, ERC20) returns(bool) 
    {
        if (_amount == 0) revert STKM__transferZero();

        bool done = super.transfer(_to, _amount);
        if (!done) revert STKM__transferFailed();

        _mintUserAccruedRewards(msg.sender);
        _mintUserAccruedRewards(_to);
        return true;
    }

    /*//////////////////////////////////////////////////////////////
                         transaction on behalf
    //////////////////////////////////////////////////////////////*/ 

    /**
     * @notice msg.sender (spender) spend/send _amount of STKM to _receiver 
     *         that belongs to _owner
     *
     * @param _owner the belonger of the STMK to be spent by msg.sender
     * @param _receiver the receiver of the transaction
     * @param _amount the amount of STKM to be sent
     *              
     */
    function transferFrom(
        address _owner, 
        address _receiver, 
        uint _amount
    ) public override(ISTKM, ERC20) returns(bool) {
        if (_amount == 0) revert STKM__transferZero();

        bool done = super.transferFrom(_owner, _receiver, _amount);
        if (!done) revert STKM__transferFromFailed();

        _mintUserAccruedRewards(_receiver);
        _mintUserAccruedRewards(_owner);
        _mintUserAccruedRewards(msg.sender);    
        
        return true;
    }  

    /** 
     * @notice allow _spender to spend msg.sender _amount amount of STKM
     * @param _spender spender who I allow my STKM to be spent
     * @param _amount amount of my STKM allowed spender to spend
     *
     */
    function approve(address _spender, uint _amount) 
        public override(ISTKM, ERC20) returns(bool) 
    {
        if (_amount == 0) revert STKM__ApprovingZero();

        _mintUserAccruedRewards(msg.sender);
        _mintUserAccruedRewards(_spender);

        _approve(msg.sender, _spender, _amount);
        return true;
    }

    /*//////////////////////////////////////////////////////////////
                         Manual Updates Reward
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice manually updates and mint STKM (if any)
     * @param _user updates and mint STKM to address _user
     *
     */
    function updateInterest(address _user) external {
        _mintUserAccruedRewards(_user);
    }    

    /*//////////////////////////////////////////////////////////////
                                 getter
    //////////////////////////////////////////////////////////////*/    

    /**
     * @notice the retreives number increases means extra rewards (earn per day) has calculated to you
     *
     * @notice This function does not mint the extra rewards. Instead, it displays the user's
     *         updated balance including accrued rewards (if any), purely for informational purposes.
     *         As a result, even if the retrieved balance appears higher than before (meaning rewards exist),
     *         `s_userLastUpdate` is not modified and no STKM is actually minted, purely a plain numbers
     *
     * @notice To officially mint the accrued extra rewards and update `s_userLastUpdate`,
     *         call `updateInterest`, or interact with any other functions to trigger reward updates.
     *
     * @param _user The address whose STKM balance (including unminted rewards) is being queried.
     *
     */
    function balanceOf(address _user) public override(ISTKM, ERC20) view returns (uint256) {
        uint rewards = _accruedDailyRewards(_user);

        if (rewards == type(uint).max) {
            return super.balanceOf(_user);
        }
        
        return super.balanceOf(_user) + rewards;
    }

    function checkInterestLastUpdate(address _user) external view returns(uint) {
        return s_userLastUpdate[_user];
    }

    /*//////////////////////////////////////////////////////////////
                            accrue interest
    //////////////////////////////////////////////////////////////*/    

    /**
     * @notice this is a helper function to help mint the user accrued rewards
     *
     */
    function _mintUserAccruedRewards(address _user) private {
        uint interest = _accruedDailyRewards(_user);

        if (interest == 0) {
            return;
        }
        if (interest == type(uint).max) {
            s_userLastUpdate[_user] = block.timestamp;
            return;
        }

        s_userLastUpdate[_user] = block.timestamp;
        _mint(_user, interest);
    }

    /**
     * the updates only takes place when user balance is not equal to zero
     * and the accomplishment of the last update is at least 1 day
     *
     *
     * 1 day == 86,400 seconds
     * 1 day = 1_000_000_000_000 ≈ USD 0.002
     *
     * formula:
     * => principle + (daily rewards * timeElapsed)
     * => principle + _accruedDailyRewards
     *
     * @param _user the user who the accrued rewards are for
     * @return accrued rewards
     *
     */
    function _accruedDailyRewards(address _user) private view returns(uint256) {
        uint lastRewardUpdates = s_userLastUpdate[_user];
        uint timeElapsed = block.timestamp - lastRewardUpdates;
        uint currentBal = super.balanceOf(_user);

        // just bought STKM. has yet to be updated at least once
        if (currentBal > 0 && lastRewardUpdates == 0) return type(uint).max;
        
        // no rewards for zero balance and/or within a day after the updates
        if (timeElapsed < 1 days || currentBal == 0) return 0;

        return 1_000_000_000_000 * (timeElapsed / 1 days);
    }

}