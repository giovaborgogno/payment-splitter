// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {PaymentSplitterWithFees} from "./PaymentSplitterWithFees.sol";
import {PaymentSplitterEscrow} from "./PaymentSplitterEscrow.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";

/**
 * @title PaymentSplitterEscrowWithFees
 * @dev An extension of PaymentSplitterEscrow contract that introduces fee functionality.
 * The contract allows payees to withdraw their share of the funds, and the owner can set a fee percentage for transactions.
 * Premium users are exempt from fees. Fees can be withdrawn by the owner.
 * The contract is initialized with the Ownable, ReentrancyGuard, and PaymentSplitterEscrow contracts.
 */
contract PaymentSplitterEscrowWithFees is PaymentSplitterEscrow, PaymentSplitterWithFees {
    using SafeERC20 for IERC20;
    using Address for address payable;

    /**
     * @dev Constructor to set the initial owner and initial fee.
     * @param initialOwner The initial owner of contract.
     * @param fee_ The initial fee percentage.
     */
    constructor(address initialOwner, uint256 fee_) PaymentSplitterWithFees(initialOwner, fee_) {}

    /**
     * @dev Native coin processes payments to multiple payees.
     * @param payees Array of recipient payees.
     * @param amounts Array of payment amounts corresponding to each address.
     */
    function pay(address[] calldata payees, uint256[] calldata amounts)
        external
        virtual
        override (PaymentSplitterEscrow, PaymentSplitterWithFees)
        payable
        nonReentrant
        validateArrays(payees, amounts)
    {
        uint256 totalAmount;
        for (uint256 i = 0; i < payees.length; i++) {
            _updateBalance(
                payees[i], 
                balanceOf(payees[i]) + amounts[i]
                );
            totalAmount += amounts[i];
            emit Payment(payees[i], amounts[i]);
        }

        uint256 fee_ = _calculateFee(totalAmount);
        _updateAcumulatedFees(acumulatedFees() + fee_);

        if (totalAmount + fee_ != msg.value)
            revert PaymentSplitterInvalidValueAmount(msg.value, totalAmount + fee_);
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
        override (PaymentSplitterEscrow, PaymentSplitterWithFees)
        nonReentrant
        validateArrays(payees, amounts) 
    {
        uint256 totalAmount;
        for (uint256 i = 0; i < payees.length; i++) {
            _updateBalance(
                token, 
                payees[i], 
                balanceOf(token, payees[i]) + amounts[i]
                );
            totalAmount += amounts[i];
        }

        uint256 fee_ = _calculateFee(totalAmount);
        _updateAcumulatedFees(token, acumulatedFees(token) + fee_);

        token.safeTransferFrom(_msgSender(), address(this), totalAmount + fee_);
    }

    /**
     * @dev Get contract version.
     * @return The contract version.
     */
    function version() external pure virtual override (PaymentSplitterEscrow, PaymentSplitterWithFees) returns (string memory) {
        return "1.3.0";
    }
}
