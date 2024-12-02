pragma solidity ^0.8.20;

import {Test, console} from "../lib/openzeppelin-contracts/lib/forge-std/src/Test.sol";
import {TToken} from "../src/testWithPermit2/TToken.sol";
import {PermitTransfer} from "../src/testWithPermit2/PermitTransfor.sol";
import {SignatureTransfer} from "../permit2/src/SignatureTransfer.sol";
import {SigUtils} from "../src/libraries/SigUtils.sol";
import {Permit2} from "../permit2/src/Permit2.sol";
import {ISignatureTransfer} from "../permit2/src/interfaces/ISignatureTransfer.sol";
import {PermitSignature} from "./utils/PermitSignature.sol";

contract TestTToken is Test, PermitSignature{
    TToken public token;
    PermitTransfer public permit;
    SignatureTransfer public signatureTransfer;
    SigUtils sigUtils;
    uint256 internal ownerPrivateKey;
    uint256 internal spenderPrivateKey;
    address internal owner;
    address internal spender;
    bytes32 DOMAIN_SEPARATOR;
    Permit2 permit2;


    function setUp() public {
        ownerPrivateKey = 0xA11CE;
        spenderPrivateKey = 0xB0B;
        owner = vm.addr(ownerPrivateKey);
        spender = vm.addr(spenderPrivateKey);
        vm.deal(owner, 5 ether);
        vm.deal(spender, 5 ether);
        vm.startPrank(owner);
        token = new TToken();
        signatureTransfer = new SignatureTransfer();
        vm.stopPrank();
        permit = new PermitTransfer(address(token), address(signatureTransfer));
        sigUtils = new SigUtils(signatureTransfer.DOMAIN_SEPARATOR());
        permit2 = new Permit2();
        DOMAIN_SEPARATOR = permit2.DOMAIN_SEPARATOR();
    }

    function test_permit() public {
        vm.startPrank(owner);
        console.log("owner:", owner);
        console.log("spender:", spender);
        // permit.permitAndTransfer(address(1), address(2), 1000, block.timestamp + 1 days, 1, 0x1, 0x2);
        SigUtils.Permit memory permitStruct = SigUtils.Permit({
            owner: address(owner),
            spender: address(spender),
            value: 1000,
            nonce: 0,
            deadline: block.timestamp + 1 days
        });
        bytes32 digest = sigUtils.getTypedDataHash(permitStruct);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerPrivateKey, digest);
        uint256 deadline = block.timestamp + 1 days;
        permit.permitAndTransfer(owner, spender, 1000, 
        deadline, v, r, s);
        vm.stopPrank();
        assertEq(token.balanceOf(spender), 1000);
    }


    function getTransferDetails(address to, uint256 amount)
        private
        pure
        returns (ISignatureTransfer.SignatureTransferDetails memory)
    {
        return ISignatureTransfer.SignatureTransferDetails({to: to, requestedAmount: amount});
    }

    function testPermitTransferFrom() public {
        console.log("owner:", owner);
        console.log("spender:", spender);
        uint256 nonce = 0;
        ISignatureTransfer.PermitTransferFrom memory permitTrans = defaultERC20PermitTransfer(address(token), nonce);
        bytes memory sig = getPermitTransferSignature(permitTrans, ownerPrivateKey, DOMAIN_SEPARATOR);

        uint256 startBalanceFrom = token.balanceOf(owner);
        uint256 startBalanceTo = token.balanceOf(spender);

        ISignatureTransfer.SignatureTransferDetails memory transferDetails = getTransferDetails(spender, 1000);

        permit2.permitTransferFrom(permitTrans, transferDetails, owner, sig);

        assertEq(token.balanceOf(owner), startBalanceFrom - 1000);
        assertEq(token.balanceOf(spender), startBalanceTo + 1000);
    }
}