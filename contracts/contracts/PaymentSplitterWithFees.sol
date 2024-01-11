// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {PaymentSplitter} from "./PaymentSplitter.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title PaymentSplitterWithFees
 * @dev An extension of PaymentSplitter contract that introduces fee functionality.
 * The contract allows the owner to set a fee percentage on transactions, accumulating fees for both native coin and ERC20 token payments.
 * Premium users are exempt from fees. Fees can be withdrawn by the owner.
 */
contract PaymentSplitterWithFees is PaymentSplitter, ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;
    using Address for address payable;

    uint256 private constant MAXIMUM_FEE = 100;

    uint256 private _fee; // Fee percentage: Maximum 1% || 1% = 100 || 0.1% = 10 || 0.01% = 1

    uint256 private _acumulatedFees;

    mapping(IERC20 => uint256) private _acumulatedFeesERC20;

    mapping (address => bool) private _premiumUsers;

    error PaymentSplitterWithFeesInvalidFeeAmount(uint256 fee);

    /**
     * @dev Constructor to set the initial owner and initial fee.
     * @param initialOwner The initial owner of contract.
     * @param fee_ The initial fee percentage.
     */
    constructor(address initialOwner, uint256 fee_) Ownable(initialOwner) {
        _setFee(fee_);
    }

    /**
     * @dev Native coin processes payments to multiple payees.
     * @param payees Array of recipient payees.
     * @param amounts Array of payment amounts corresponding to each address.
     */
    function pay(address[] calldata payees, uint256[] calldata amounts)
        external
        virtual
        override
        payable
        validateArrays(payees, amounts)
    {
        uint256 totalAmount = _calculateTotalAmount(amounts);
        uint256 fee_ = _calculateFee(totalAmount);

        if (totalAmount + fee_ != msg.value)
            revert PaymentSplitterInvalidValueAmount(msg.value, totalAmount + fee_);

        for (uint256 i = 0; i < payees.length; i++) {
            payable(payees[i]).sendValue(amounts[i]);
            emit Payment(payees[i], amounts[i]);
        }

       _updateAcumulatedFees(acumulatedFees() + fee_);

    }

    /**
     * @dev ERC20 processes payments to multiple payees.
     * @param token ERC20 token to be used for payments.
     * @param payees Array of recipient payees.
     * @param amounts Array of payment amounts corresponding to each address.
     */
    function pay(IERC20 token, address[] calldata payees, uint256[] calldata amounts) 
        external 
        virtual
        override
        validateArrays(payees, amounts) 
    {
        uint256 totalAmount = _calculateTotalAmount(amounts);
        uint256 fee_ = _calculateFee(totalAmount);
        
        if (totalAmount + fee_ > token.balanceOf(_msgSender()))
            revert ERC20InsufficientBalance(
                _msgSender(), 
                token.balanceOf(_msgSender()), 
                totalAmount + fee_
                );

        for (uint256 i = 0; i < payees.length; i++) {
            token.safeTransferFrom(_msgSender(), payees[i], amounts[i]);
            emit Payment(payees[i], amounts[i]);
        }

        _updateAcumulatedFees(token, acumulatedFees(token) + fee_);

        token.safeTransferFrom(_msgSender(), address(this), fee_);
    }

    /**
     * @dev Set the fee percentage.
     * @param fee_ The new fee percentage.
     */
    function setFee(uint256 fee_) external onlyOwner {
        _setFee(fee_);
    }

    /**
     * @dev Withdraw accumulated native coin to the owner.
     */
    function withdrawFees() external nonReentrant onlyOwner {
        uint256 amount = acumulatedFees();
        _updateAcumulatedFees(0); 
        emit Withdrawal(owner(), amount);
        payable(owner()).sendValue(amount);
    }

    /**
     * @dev Withdraw accumulated ERC20 fees to the owner.
     * @param token ERC20 token for withdrawal.
     */
    function withdrawFees(IERC20 token) external nonReentrant onlyOwner {
        uint256 amount = acumulatedFees(token);
        _updateAcumulatedFees(token, 0);
        emit WithdrawalERC20(token, owner(), amount);
        token.safeTransfer(owner(), amount);
    }

    /**
     * @dev Sets the premium status for a user.
     * @param user The address of the user whose premium status is to be updated.
     * @param newStatus The new premium status to be assigned (`true` for premium, `false` for non-premium).
     */
    function setPremiumUser(address user, bool newStatus) external onlyOwner {
        _premiumUsers[user] = newStatus;
    }

    /**
     * @dev Get contract version.
     * @return The contract version.
     */
    function version() external pure virtual override returns (string memory) {
        return "1.1.0";
    }

    /**
     * @dev Get the fee percentage.
     * @return The fee percentage.
     */
    function fee() public view returns (uint256) {
        return _fee;
    }

    /**
     * @dev Get the total accumulated native coin fees.
     * @return The total accumulated native coin fees.
     */
    function acumulatedFees() public view returns (uint256) {
        return _acumulatedFees;
    }

    /**
     * @dev Get the total accumulated ERC20 token fees.
     * @param token ERC20 token for which to get accumulated fees.
     * @return The total accumulated ERC20 token fees.
     */
    function acumulatedFees(IERC20 token) public view returns (uint256) {
        return _acumulatedFeesERC20[token];
    }

    /**
     * @dev Retrieves the premium status of a user.
     * @param user The address of the user whose premium status is queried.
     * @return A boolean indicating whether the user has premium status (`true` for premium, `false` for non-premium).
     */
    function isPremiumUser(address user) public view returns (bool) {
        return _premiumUsers[user];
    }

    /**
     * @dev Internal function to set the fee percentage.
     * @param fee_ The new fee percentage.
     */
    function _setFee(uint256 fee_) internal {
        if (fee_ > MAXIMUM_FEE)
            revert PaymentSplitterWithFeesInvalidFeeAmount(fee_);

        _fee = fee_;
    }

    /**
     * @dev Internal function to update the total accumulated native coin fees.
     * @param newAmount The new total accumulated fees for native coins.
     */
    function _updateAcumulatedFees(uint256 newAmount) internal {
        _acumulatedFees = newAmount;
    }

    /**
     * @dev Internal function to update the total accumulated fees for a specific ERC20 token.
     * @param token The ERC20 token for which to update the accumulated fees.
     * @param newAmount The new total accumulated fees for the specified ERC20 token.
     */
    function _updateAcumulatedFees(IERC20 token, uint256 newAmount) internal {
        _acumulatedFeesERC20[token] = newAmount;
    }

    /**
     * @dev Internal function to calculate the fee based on the given amount.
     * @param amount The total payment amount.
     * @return The calculated fee or zero if msg.sender is a premium user.
     */
    function _calculateFee(uint256 amount) internal view returns (uint256) {
        if (isPremiumUser(_msgSender()))
            return 0;
        return (amount * fee()) / 10000;
    }
}
