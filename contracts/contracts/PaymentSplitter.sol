// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {IPaymentSplitter} from "./IPaymentSplitter.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {Context} from "@openzeppelin/contracts/utils/Context.sol";

/**
 * @title PaymentSplitter
 * @dev A contract for processing payments to multiple payees using ERC20 tokens or native coins.
 * The contract allows the owner to set a fee percentage on transactions, accumulating fees for both native coin and ERC20 token payments.
 * Fees can be withdrawn by the owner. The contract is initialized with the Ownable contract for ownership control.
 */
contract PaymentSplitter is IPaymentSplitter, Context {
    using SafeERC20 for IERC20;
    using Address for address payable;

    uint256 private constant MAXIMUM_ARRAY_LENGHT = 500;

    /**
     * @dev Modifier to validate the lengths of arrays.
     */
    modifier validateArrays(address[] calldata payees, uint256[] calldata amounts) {
        if (payees.length != amounts.length)
            revert PaymentSplitterMismatchedArrayLenghts(payees.length, amounts.length);

        if (payees.length == 0 || payees.length > MAXIMUM_ARRAY_LENGHT)
            revert PaymentSplitterInvalidArrayLenght(payees.length);

        _;
    }

    /**
     * @dev Native coin processes payments to multiple payees.
     * @param payees Array of recipient payees.
     * @param amounts Array of payment amounts corresponding to each address.
     */
    function pay(address[] calldata payees, uint256[] calldata amounts)
        external
        virtual
        payable
        validateArrays(payees, amounts)
    {
        uint256 totalAmount = _calculateTotalAmount(amounts);

        if (totalAmount != msg.value)
            revert PaymentSplitterInvalidValueAmount(msg.value, totalAmount);

        for (uint256 i = 0; i < payees.length; i++) {
            payable(payees[i]).sendValue(amounts[i]);
            emit Payment(payees[i], amounts[i]);
        }
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
        validateArrays(payees, amounts) 
    {
        uint256 totalAmount = _calculateTotalAmount(amounts);
        
        if (totalAmount > token.balanceOf(_msgSender()))
            revert ERC20InsufficientBalance(
                _msgSender(), 
                token.balanceOf(_msgSender()), 
                totalAmount
                );

        for (uint256 i = 0; i < payees.length; i++) {
            token.safeTransferFrom(_msgSender(), payees[i], amounts[i]);
            emit PaymentERC20(token, payees[i], amounts[i]);
        }
    }

    /**
     * @dev Get contract version.
     * @return The contract version.
     */
    function version() external pure virtual returns (string memory) {
        return "1.0.0";
    }

    /**
     * @dev Internal pure function to calculate the total sum of amounts in an array.
     * @param amounts An array of unsigned integers representing payment amounts.
     * @return The total sum of all amounts in the provided array.
     */
    function _calculateTotalAmount(uint256[] calldata amounts) internal pure returns (uint256) {
        uint256 totalAmount = 0;
        for (uint256 i = 0; i < amounts.length; i++) {
            totalAmount += amounts[i];
        }
        return totalAmount;
    }
}
