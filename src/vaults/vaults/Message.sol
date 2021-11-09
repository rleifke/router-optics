// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.6.11;

import "@summa-tx/memview-sol/contracts/TypedMemView.sol";

library Message {
    using TypedMemView for bytes;
    using TypedMemView for bytes29;

    enum Types {
        Invalid, // 0
        RateOne, // 1 
        RateTwo // 2
    }

    // ============ Formatters ============

    /**
     * @notice Format a Deposit 
     * @param _interest The lending rate translated as the interest percentage
     * TODO: Add more parameters, like collateral amount 
     * @return The encoded bytes message
     */
    function formatLend(uint256 _number) internal pure returns (bytes memory) {
        return abi.encodePacked(uint8(Types.Deposit), _interest);
    }

     /**
     * @notice Format a Deposit 
     * @param _interest The lending rate translated as the interest percentage
     * TODO: Add more parameters 
     * @return The encoded bytes message
     */
    function formatBorrow(uint256 _number) internal pure returns (bytes memory) {
        return abi.encodePacked(uint8(Types.Deposit), _interest);
    }


    // ============ Identifiers ============

    /**
     * @notice Get the type that the TypedMemView is cast to
     * @param _view The message
     * @return _type The type of the message (one of the enum Types)
     */
    function messageType(bytes29 _view) internal pure returns (Types _type) {
        _type = Types(uint8(_view.typeOf()));
    }

    /**
     * @notice Determine whether the message is RateOne
     * @param _view The message
     * @return _isTypeA True if the message is RateOne
     */
    function isRateOne(bytes29 _view) internal pure returns (bool _isTypeA) {
        _isTypeA = messageType(_view) == Types.A;
    }

/**
     * @notice Determine whether the message is RateTwo
     * @param _view The message
     * @return _isTypeA True if the message is RateTwo
     */
    function isRateTwo(bytes29 _view) internal pure returns (bool _isTypeA) {
        _isTypeA = messageType(_view) == Types.A;
    }
    // ============ Getters ============

    /**
     * @notice Parse the match ID sent within a RateOne or RateTwo message 
     * @dev The number is encoded as a uint32 at index 1
     * @param _view The message
     * @return The match id encoded in the message
     */
    function roundId(bytes29 _view) internal pure returns (uint32) {
        // At index 1, read 4 bytes as a uint, and cast to a uint32
        return uint32(_view.indexUint(1, 4));
    }

    /**
     * @notice Parse the volley count sent within a Lend or Borrow message
     * @dev The number is encoded as a uint256 at index 1
     * @param _view The message
     * @return The count encoded in the message
     */
    function interest(bytes29 _view) internal pure returns (uint256) {
        // At index 1, read 32 bytes as a uint
        return _view.indexUint(1, 32);
    }
}