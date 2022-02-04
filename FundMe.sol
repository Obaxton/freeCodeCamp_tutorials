// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.9.0;

//This import is imports the following interface thus it is commented out to avoid the redundancy.
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract FundMe {

  mapping(address => uint256) public addressToAmountFunded;
  address[] public funders;
  address owner;

  //set the owner of the contract to the creator of the contract
  constructor() {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner, "Only the owner can call this.");
    _;
  }

  function fund() public payable {
    uint256 minimumUSD = 50 * (10 ** 18); //setting a minimum amount of 50 USD and converting it to gwei.
    require(getConversionRate(msg.value) >= minimumUSD, "Not enough ETH was sent."); //if the sent value is less than or equal to minimumUSD, the transaction along with any extra gas fees will be reverted back to the sender.
    addressToAmountFunded[msg.sender] += msg.value; //adds mapping from the sender address to the amount they funded
    funders.push(msg.sender); //adds to the funders array the address of each sender
  }

  //gets the version of the AggregatorV3Interface contract at the specified address.
  function getVersion() public view returns (uint256) {
    AggregatorV3Interface priceFeed = AggregatorV3Interface(0x9326BFA02ADD2366b30bacB125260Af641031331); //this address is the for the ETH to USD Kovan network.
    return priceFeed.version();
  }

  //gets the current price of ETH in USD
  function getPrice() public view returns(uint256){
    AggregatorV3Interface priceFeed = AggregatorV3Interface(0x9326BFA02ADD2366b30bacB125260Af641031331);
    (,int256 answer,,,) = priceFeed.latestRoundData(); //the commas indicate the function has variables being returned but they are not needed in this scenario. So they are essentially blank return values.
    return uint256(answer * 10000000000);
  }

  //gets a conversion rate of entered ETH, Gwei, or Wei amount to USD
  function getConversionRate(uint256 ethAmount) public view returns(uint256) {
    uint256 ethPrice = getPrice();
    uint256 ethAmountInUSD = (ethPrice * ethAmount) / 1000000000000000000;
    return ethAmountInUSD;
  }

  //allow the owner to withdraw all the funds on the contract
  function withdraw() public payable onlyOwner {
    payable(msg.sender).transfer(address(this).balance);

    //loop through funders array to get all the addresses of all funders and set their amount funded to 0
    for(uint256 i = 0; i < funders.length; i++) {
      address funder = funders[i];
      addressToAmountFunded[funder] = 0;
    }

    //reset the funders array by setting it to a new address array
    funders = new address[](0);
  }
}
