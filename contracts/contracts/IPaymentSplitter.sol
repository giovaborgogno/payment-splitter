// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IPaymentSplitter{

    event Payment(address indexed to, uint256 amount);
    event PaymentERC20(IERC20 token, address indexed to, uint256 amount);
    event Withdrawal(address indexed to, uint256 amount);
    event WithdrawalERC20(IERC20 token, address indexed to, uint256 amount);

    error PaymentSplitterMismatchedArrayLenghts(uint256 payeesLenght, uint256 amountsLenght);
    error PaymentSplitterInvalidArrayLenght(uint256 arrayLenght);
    error PaymentSplitterInvalidValueAmount(uint256 value, uint256 valueRequired);
    error ERC20InsufficientBalance(address sender, uint256 balance, uint256 needed);

    /**
     * @dev Native coin processes payments to multiple payees.
     * @param payees Array of recipient payees.
     * @param amounts Array of payment amounts corresponding to each address.
     */
    function pay(address[] calldata payees, uint256[] calldata amounts) external payable;

    /**
     * @dev ERC20 processes payments to multiple payees.
     * @param token ERC20 token to be used for payments.
     * @param payees Array of recipient payees.
     * @param amounts Array of payment amounts corresponding to each address.
     */
    function pay(IERC20 token, address[] calldata payees, uint256[] calldata amounts) external;
}
