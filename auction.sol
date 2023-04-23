//SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.0 <0.9.0;

contract Auction{
    // Define local variables
    address payable public owner;
    uint public startBlock;
    uint public endBlock;
    string public ipfsHash; // Off-chain solutions to save information
    
    enum State {Started, Running, Ended, Canceled}
    State public auctionState;

    uint public highestBindingBid;
    address payable public highestBidder;

    mapping(address => uint) public bids; // Addresses of the bidders & their bids
    uint bidIncrement; // Bid increment

    // Initialize local variables
    constructor(){
        owner = payable(msg.sender);
        auctionState = State.Running;
        startBlock = block.number;
        endBlock = startBlock + 40320;
        ipfsHash = "";
        bidIncrement = 100;
    }

    // Create modifiers
    // Authorization
    modifier notOwner(){
        require(msg.sender != owner);
        _;
    }
    modifier onlyOwner(){
        require(msg.sender == owner);
        _;
    }
    // Time modifiers
    modifier afterStart(){
        require(block.number >= startBlock);
        _;
    }
    modifier beforeEnd(){
        require(block.number <= endBlock);
        _;
    }



    // Functions
    // Takes two uint parameters and returns the smallest of the two values.
    function min(uint a, uint b) pure internal returns(uint){
        if(a <= b){
            return a;
        }else{
            return b;
        }
    }

    function cancelAuction() public onlyOwner{
        auctionState = State.Canceled;
    }

    function placeBid() public payable notOwner afterStart beforeEnd{
        // Check if the auction is running and if the bid is atleast 100 wei
        require(auctionState == State.Running);
        require(msg.value >= 100);

        uint currentBid = bids[msg.sender] + msg.value;
        require(currentBid > highestBindingBid);
        
        // Update bids mapping
        bids[msg.sender] = currentBid;

        // Outbidding mechanism
        if(currentBid <= bids[highestBidder]){
            highestBindingBid = min(currentBid + bidIncrement, bids[highestBidder]);
        }else{
            highestBindingBid = min(currentBid, bids[highestBidder] + bidIncrement);
            highestBidder = payable(msg.sender);
        }

    }

    function finalizeAuction() public{
        require(auctionState == State.Canceled || block.number > endBlock);
        require(msg.sender == owner || bids[msg.sender] > 0);

        address payable recipient;
        uint value;

        if(auctionState == State.Canceled){ // Auction was cancelled
            recipient = payable(msg.sender);
            value = bids[msg.sender];
        }else{ // auction ended (not canceled)
            if(msg.sender == owner){ // this is the owner
                recipient == owner;
                value = highestBindingBid;
            }else{ // this is a bidder
                if(msg.sender == highestBidder){
                    recipient = highestBidder;
                    value = bids[highestBidder] - highestBindingBid;
                }else{ // this is neither the owner nor the highestBidder
                    recipient = payable(msg.sender);
                    value = bids[msg.sender];
                }
            }
        }
        recipient.transfer(value);
    }

}
