pragma solidity ^0.8.13;

import {Test, console} from "../lib/openzeppelin-contracts/lib/forge-std/src/Test.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
                                    // lib/chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol


contract TestLink {
    // BTC-USD: 0x5741306c21795FdCBb9b265Ea0255F499DFe515C
    AggregatorV3Interface internal priceFeed;
    constructor() {
        priceFeed = AggregatorV3Interface(
            0x5741306c21795FdCBb9b265Ea0255F499DFe515C
        );
    }

    function getLatestPrice() public view returns (int) {
        // prettier-ignore
        (
            /* uint80 roundID */,
            int price,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = priceFeed.latestRoundData();
        return price;
    }

}