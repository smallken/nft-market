pragma solidity ^0.8.20;

import {TToken} from "./TToken.sol";
import "../../permit2/src/SignatureTransfer.sol";
import "../../permit2/src/interfaces/ISignatureTransfer.sol";

contract PermitTransfer {

    address public token;
    address public signatureTransfer;
    struct TokenPermissions {
        // ERC20 token address
        address token;
        // the maximum amount that can be spent
        uint256 amount;
    }
    struct PermitTransferFrom {
        TokenPermissions permitted;
        // a unique value for every token owner's signature to prevent signature replays
        uint256 nonce;
        // deadline on the permit signature
        uint256 deadline;
    }
    struct SignatureTransferDetails {
        // recipient address
        address to;
        // spender requested amount
        uint256 requestedAmount;
    }
    constructor(address _token, address _signatureTransfer) {
        token = _token;
        signatureTransfer = _signatureTransfer;
    }

    function permitAndTransfer(address owner, address spender, 
    uint256 value, uint256 deadline, uint8 v, bytes32 r, 
    bytes32 s) external {
        ISignatureTransfer.TokenPermissions memory permitted = ISignatureTransfer.TokenPermissions({
            token: token,
            amount: value
        });

        ISignatureTransfer.PermitTransferFrom memory permit = ISignatureTransfer.PermitTransferFrom({
            permitted: permitted,
            nonce: 0,
            deadline: deadline
        });

        ISignatureTransfer.SignatureTransferDetails memory transferDetails = ISignatureTransfer.SignatureTransferDetails({
            to: spender,
            requestedAmount: value
        });


        /**
         *  function permitTransferFrom(
        PermitTransferFrom memory permit,
        SignatureTransferDetails calldata transferDetails,
        address owner,
        bytes calldata signature
         */
        bytes memory signatureBytes = abi.encodePacked(v, r, s);
        ISignatureTransfer(signatureTransfer).permitTransferFrom(permit, transferDetails, owner, signatureBytes);
        // permitWitnessTransferFrom(permit, transferDetails, owner, witness, witnessTypeString, signature);
    }

}