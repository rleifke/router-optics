// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.6.11;

// ============ External Imports ============
import {TypedMemView} from "@summa-tx/memview-sol/contracts/TypedMemView.sol";
// ============ Internal Imports ============
import {Message} from "./MessageTemplate.sol";
import {Router} from "../Router.sol";
import {XAppConnectionClient} from "../XAppConnectionClient.sol";

/*
============ CheckRate xApp ============
The cross-chain lending xApp is capable of initiating rate checks between two chains. Ideally, the application checks which rate is
higher and calls on a method on a remote chain to deposit capital at the highest lending rate.
A round consists of "checks" which compare interest rates back-and-forth between the two chains via Optics.

The first check in a round is always a RateOne check.
When a Router receives a RateOne message, it returns a RateTwo.
When a Router receives a RateTwo message, it returns a RateOne.

The Routers keep track of the number of checks in a given round,
and emit events for each Sent and Received check so that lenders can find the best rate.
*/

contract RouterTemplate is Router {
    // ============ Libraries ============

    using TypedMemView for bytes;
    using TypedMemView for bytes29;
    using CheckRateMessage for bytes29;

    // ============ Mutable State ============
    uint32 nextRound;

    // ============ Events ============

    event Received(
        uint32 indexed domain,
        uint32 indexed roundId,
        uint256 number,
        bool isRateOne
    );

    event Sent(
        uint32 indexed domain,
        uint32 indexed roundId,
        uint256 number,
        bool isRateOne
    );

    // ============ Constructor ============
 
    // deploy to Optics test instance 

    constructor(address _xAppConnectionManager) {
        __XAppConnectionClient_initialize(_xAppConnectionManager);
    }

    // ============ Handle message functions ============

    /**
     * @notice Handle "checks" sent via Optics from other remote LendingRate Routers
     * @dev Called by an Optics Replica contract while processing a message sent via Optics
     * @param _origin The domain the message is coming from
     * @param _sender The address the message is coming from
     * @param _message The message in the form of raw bytes
     */
    function handle(
        uint32 _origin,
        bytes32 _sender,
        bytes memory _message
    ) external override onlyReplica onlyRemoteRouter(_origin, _sender) {
        bytes29 _msg = _message.ref(0);
        if (_msg.isRateOne()) {
            _handleRateOne(_origin, _msg);
        } else if (_msg.isRateTwo()) {
            _handleRateTwo(_origin, _msg);
        } else {
            // if _message doesn't match any valid actions, revert
            require(false, "!valid action");
        }
    }

    /**
     * @notice Handle a RateOne volley
     * @param _origin The domain that sent the volley
     * @param _message The message in the form of raw bytes
     */
    function _handleRateOne(uint32 _origin, bytes29 _message) internal {
        bool _isRateOne = true;
        _handle(_origin, _isRateOne, _message);
    }

    /**
     * @notice Handle a RateTwo volley
     * @param _origin The domain that sent the volley
     * @param _message The message in the form of raw bytes
     */
    function _handleRateTwo(uint32 _origin, bytes29 _message) internal {
        bool _isRateTwo = false;
        _handle(_origin, _isRateTwo, _message);
    }

    /**
     * @notice Upon receiving a check, emit an event, increment the count and return another 
     check from different chain, "an opposite check"
     * @param _origin The domain that sent the check
     * @param _isRate True if the check received is RateOne, false if it is RateTwo
     * @param _message The message in the form of raw bytes
     */
    function _handle(
        uint32 _origin,
        bool _isRateOne,
        bytes29 _message
    ) internal {
        // get the volley count for this game
        uint256 _count = _message.number();
        uint32 _match = _message.roundId();
        // emit a Received event
        emit Received(_origin, _round, _number, _isRateOne);
        // send the opposite check back
        _send(_origin, !_isRateOne, _round, _number + 1);
    }

    // ============ Dispatch message functions ============

    /**
     * @notice Initiate a PingPong match with the destination domain
     * by sending the first Ping volley.
     * @param _destinationDomain The domain to initiate the match with
     */
    function initiateCheckRateRound(uint32 _destinationDomain) external {
        // the PingPong match always begins with a RateOne check
        bool _isRateOne = true;

        // increment round counter
        // uint32 _match = nextMatch;
        // nextMatch = _match + 1;

        // send the first check to the destination domain
        _send(_destinationDomain, _isRateOne, _round, 0);
    }

    /**
     * @notice Send RateOne or RateTwo check to the destination domain
     * @param _destinationDomain The domain, which is the chain that the check is to sent to.
     * @param _isRateOne True if the check to send is RateOne, false if it is RateTwo
     * @param _number The number of check in this match
     */
    function _send(
        uint32 _destinationDomain,
        bool _isRateOne,
        uint32 _round,
        uint256 _number
    ) internal {
        // get the xApp Router at the destinationDomain
        bytes32 _remoteRouterAddress = _mustHaveRemote(_destinationDomain);
        // format the ping message
        bytes memory _message = _isPing
            ? CheckRateMessage.formatRateOne(_round, _number)
            : CheckRateMessage.formatRateOne(_round, _number);
        // send the message to the xApp Router
        (_home()).dispatch(_destinationDomain, _remoteRouterAddress, _message);
        // emit a Sent event
        emit Sent(_destinationDomain, _round, _number, _isRateOne);
    }
}