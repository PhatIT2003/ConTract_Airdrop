// SPDX-License-Identifier: MIT
// (contracts/PIRC20/extensions/IPIRC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IPIRC20.sol";

/**
 * @dev Interface for the optional metadata functions from the PIRC20 standard.
 *
 * _Available since v4.1._
 */
interface IPIRC20Metadata is IPIRC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}
