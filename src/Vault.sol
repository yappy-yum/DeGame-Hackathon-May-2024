// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {ERC20, ERC20Burnable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract Vault is ERC20("STICKMAN", "STKM"), ERC20Burnable, Ownable(msg.sender) {

    mapping(address user => uint256 lastUpdate) private _userLastUpdate; 

    /*//////////////////////////////////////////////////////////////
                              custom error
    //////////////////////////////////////////////////////////////*/

    error Vault__MintZero();
    error Vault__BurnZero();
    error Vault__BurnOverflow();

    /*//////////////////////////////////////////////////////////////
                                modifier
    //////////////////////////////////////////////////////////////*/

    /// @notice automatic revert if the msg.sender is a contract address
    modifier noContract() {
        assembly {
            if gt(extcodesize(caller()), 0) {
                revert (0, 0)
            }
        }
        _;
    }  

    /// @notice automatic revert if re-entrancy is detected
    modifier noReentrant {
        assembly {
            if tload(0) { revert(0, 0) }
            tstore(0, 1)
        }
        _;
        assembly { tstore(0, 0) }
    }     

    /*//////////////////////////////////////////////////////////////
                                  mint
    //////////////////////////////////////////////////////////////*/     

    /**
     * @notice pay to get STKM
     * @dev msg.sender == address(0) is optional since its hypothetically impossible to be  
     *      false, and also the zero address checks will also be done inside the _mint function
     */
    function buySTKM() external payable noReentrant noContract {
        if (msg.value == 0) revert Vault__MintZero();

        _mint(msg.sender, msg.value);
        _mintUserAccruedRewards(msg.sender);
    }

    /**
     * @notice this function is used to provide hard earned STKM to the user
     * @param _to user address
     * @param _amount amount of STKM to give
     *
     */
    function giveSTKM(address _to, uint256 _amount) external noReentrant onlyOwner {
        if (_amount == 0) revert Vault__MintZero();
        _mint(_to, _amount);

        if (_userLastUpdate[_to] == 0) {
            _userLastUpdate[_to] = block.timestamp;
        }
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
    function withdrawSTKM(uint256 _amount) external noReentrant noContract {
        uint userOwnedBef = super.balanceOf(msg.sender);
        uint userOwnedAft = userOwnedBef + _accruedDailyRewards(msg.sender);

        if (_amount == 0) revert Vault__BurnZero();
        if (userOwnedAft < _amount) revert Vault__BurnOverflow();

        _mintUserAccruedRewards(msg.sender);
        _burn(msg.sender, _amount);

        (bool ok, ) = msg.sender.call{value: _amount}("");
        require(ok, "Vault: burn transaction failed");

    }

    /*//////////////////////////////////////////////////////////////
                                 getter
    //////////////////////////////////////////////////////////////*/    

    function userBalance(address _user) external view returns (uint256) {
        return super.balanceOf(_user) + _accruedDailyRewards(_user);
    }

    /*//////////////////////////////////////////////////////////////
                            accrue interest
    //////////////////////////////////////////////////////////////*/    

    /**
     * @notice this is a helper function to help mint the user accrued rewards
     *
     */
    function _mintUserAccruedRewards(address _user) private {
        _mint(_user, _accruedDailyRewards(_user));
        _userLastUpdate[msg.sender] = block.timestamp;
    }

    /**
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
        uint lastUpdate = _userLastUpdate[_user];
        uint timeElapsed = block.timestamp - lastUpdate;

        if 
        (
            lastUpdate == 0 ||
            timeElapsed < 1 days
        ) return 0;

        return 1_000_000_000_000 * (timeElapsed / 1 days);
    }

}