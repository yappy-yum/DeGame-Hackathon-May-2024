// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

interface ISTKM {

    /**
     * @notice pay to get STKM (child contract will handle the payment)
     *
     * @param _to user address
     * @param _amount amount of STKM (arg == msg.value in child contract)
     *
     */
    function buySTKM(address _to, uint _amount) external; 

    /**
     * @notice this function is used to provide hard earned STKM to the user (only callable by owner)
     * @param _to user address
     * @param _amount amount of STKM to give
     *
     */
    function giveSTKM(address _to, uint256 _amount) external;       

    /**
     *
     * @notice burn STKM and convert to crypto coin for withdrawal
     * @param _user user address to be converted and withdraw to
     * @param _amount token amount to be burnt
     *
     */
    function withdrawSTKM(address _user, uint256 _amount) external;

    /**
     * @notice transfer `_amount` of STKM directly from msg.sender to address `_to`
     * @param _to user address to be transfered to
     * @param _amount amount of STKM to transfer
     *
     */
    function transfer(address _to, uint _amount) external returns(bool); 

    /**
     * @notice msg.sender (spender) spend/send _amount of STKM to _receiver 
     *         that belongs to _owner
     *
     * @param _owner the belonger of the STMK to be spent by msg.sender
     * @param _receiver the receiver of the transaction
     * @param _amount the amount of STKM to be sent
     *
     * @notice needed by child contract: 
     *              _owner: child caller
     *              _receiver: other person set by child caller
     *              _spender (msg.sender): child contract
     *              
     */
    function transferFrom(address _owner, address _receiver, uint _amount) external returns(bool);  

    /** 
     * @notice allow _spender to spend my _amount amount of STKM
     * @param _spender spender who I'm allowing my STKM to be spent
     * @param _amount amount of my STKM allowed spender to spend
     *
     */
    function approve(address _spender, uint _amount) external returns(bool); 

    /**
     * @notice manually updates and mint STKM (if any)
     * @param _user updates and mint STKM to address _user
     *
     */
    function updateInterest(address _user) external; 

    /**
     * @notice the retreives number increases means extra rewards (earn per day) has calculated to you
     *
     * @notice This function does not mint the extra rewards. Instead, it displays the user's
     *         updated balance including accrued rewards (if any), purely for informational purposes.
     *         As a result, even if the retrieved balance appears higher than before (meaning rewards exist),
     *         `STKM.s_userLastUpdate` is not modified and no STKM is actually minted, purely a plain numbers
     *
     * @notice To officially mint the accrued extra rewards and update `STKM.s_userLastUpdate`,
     *         call `updateInterest`, or interact with any other functions to trigger reward updates.
     *
     * @param _user The address whose STKM balance (including unminted rewards) is being queried.
     *
     */
    function balanceOf(address _user) external view returns (uint256);

    /**
     * @notice check last update time the user has been updated (minted) with the daily rewards
     * @param _user user address
     *
     */
    function checkInterestLastUpdate(address _user) external view returns(uint);

}