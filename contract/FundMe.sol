// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {PriceConverter} from "./PriceConverter.sol";

error NotOwner();

contract FundMe {
    using PriceConverter for uint256;

    mapping (address => uint256) public addressToAmountFunded;
    address[] public funders;
    uint256 public constant MINIMUM_USD = 5 * 1e18; // $5
    address public immutable sysOwner;

    constructor() {
        sysOwner = msg.sender;
    }

    function fund() public payable {
        // Allow users to send $5
        // Have a minimum $5 sent
        require(msg.value.getConversionRate() > MINIMUM_USD, "You need to spend more ETH!");
        addressToAmountFunded[msg.sender] += msg.value;
        funders.push(msg.sender);
    }

    modifier onlyOwner() {
        if (msg.sender != sysOwner) revert NotOwner();
        _;
    }

    function withdraw() public onlyOwner {
        for (uint256 funderIndex = 0; funderIndex < funders.length; funderIndex++) {
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }
        funders = new address[](0);

        (bool callSuccess, ) = sysOwner.call{value: address(this).balance}("");
        require(callSuccess, "Call failed");
    }

    fallback() external payable { 
        fund();
    }

    receive() external payable { 
        fund();
    }
}