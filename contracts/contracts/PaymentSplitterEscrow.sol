// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {PaymentSplitter} from "./PaymentSplitter.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title PaymentSplitterEscrow
 * @dev A contract for processing payments to multiple payees using ERC20 tokens or native coins, with funds held in escrow.
 * The contract allows payees to withdraw their share of the funds, and the owner can set a fee percentage for transactions.
 * Fees can be withdrawn by the owner. The contract is initialized with the Ownable and ReentrancyGuard contracts.
 */
contract PaymentSplitterEscrow is PaymentSplitter, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using Address for address payable;

    mapping (address => uint256) private _balanceOf;

    mapping (IERC20 => mapping (address => uint256)) private _balanceOfERC20;

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

        if (totalAmount != msg.value)
            revert PaymentSplitterInvalidValueAmount(msg.value, totalAmount);
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
            emit PaymentERC20(token, payees[i], amounts[i]);
        }

        token.safeTransferFrom(_msgSender(), address(this), totalAmount);
    }

    /**
     * @dev Withdraw balance of native coin.
     */
    function withdraw() external nonReentrant {
        address payee = _msgSender();
        uint256 amount = balanceOf(payee);
        _updateBalance(payee, 0);
        emit Withdrawal(payee, amount);
        payable(payee).sendValue(amount);
    }

    /**
     * @dev Withdraw balance of ERC20.
     * @param token ERC20 token for withdrawal.
     */
    function withdraw(IERC20 token) external nonReentrant {
        address payee = _msgSender();
        uint256 amount = balanceOf(token, payee);
        _updateBalance(token, payee, 0);
        emit WithdrawalERC20(token, payee, amount);
        token.safeTransfer(payee, amount);
    }

    /**
     * @dev Get contract version.
     * @return The contract version.
     */
    function version() external pure virtual override returns (string memory) {
        return "1.2.0";
    }

    /**
     * @dev Retrieves the balance of native coins (ETH) for a specific payee.
     * @param payee The address of the payee for whom to retrieve the balance.
     * @return The balance of native coins (ETH) for the specified payee.
     */
    function balanceOf(address payee) public view returns (uint256) {
        return _balanceOf[payee];
    }

    /**
     * @dev Retrieves the balance of a specific ERC-20 token for a given payee.
     * @param token The ERC-20 token for which to retrieve the balance.
     * @param payee The address of the payee for whom to retrieve the balance.
     * @return The balance of the specified ERC-20 token for the specified payee.
     */
    function balanceOf(IERC20 token, address payee) public view returns (uint256) {
        return _balanceOfERC20[token][payee];
    }

    function _updateBalance(address payee, uint256 newBalance) internal {
        _balanceOf[payee] = newBalance;
    }

    function _updateBalance(IERC20 token, address payee, uint256 newBalance) internal {
        _balanceOfERC20[token][payee] = newBalance;
    }
}
