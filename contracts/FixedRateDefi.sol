pragma solidity ^0.5.1;

contract cDAI {
    function mint(uint mintAmount) public returns (uint);

    function redeemUnderlying(uint redeemAmount) public returns (uint);

    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    function transfer(address to, uint tokens) public returns (bool success);

    function balanceOf(address tokenOwner) public view returns (uint balance);

    function exchangeRateCurrent() public returns (uint);
}

contract DAI {
    function transfer(address to, uint tokens) public returns (bool success);

    function balanceOf(address tokenOwner) public view returns (uint balance);

    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    function approve(address spender, uint tokens) public returns (bool success);
}

contract FixedRateDefi {

    address public cDaiContractAddress = address(0xF5DCe57282A584D2746FaF1593d3121Fcac444dC);
    address public daiContractAddress = address(0x89d24A6b4CcB1B6fAA2625fE562bDD9a23260359);
    cDAI public cDaiContract = cDAI(cDaiContractAddress);
    DAI public daiContract = DAI(daiContractAddress);

    uint public secondsPerYear = 31536000;

    address public investor; // investor address
    address public marketMaker; // marketMaker address
    uint public settleTime; // when the contract was settled
    uint public acceptTime; // when the contract was accepted

    uint public principal; // required deposit principal amount
    uint public interestCollateral; // collateral deposited by the market maker to ensure investor gets paid
    uint public length; // how long for the contract to mature

    modifier ensureContractNotAccepted() {
        require(acceptTime == 0);
        _;
    }

    modifier ensureOnlyInvestor() {
        require(msg.sender == investor);
        _;
    }

    modifier ensureOnlyMarketMaker() {
        require(msg.sender == marketMaker);
        _;
    }

    modifier ensureExpiredOrSettled() {
        require(contractExpired() || contractSettled());
        _;
    }

    modifier ensureContractAccepted() {
        require(acceptTime > 0);
        _;
    }

    function divider(uint numerator, uint denominator, uint precision) public pure returns (uint) {
        return numerator * (uint(10) ** uint(precision)) / denominator;
    }

    // getter function to check when the contract expires
    function endTime() public view returns (uint) {
        if (acceptTime > 0) {
            return length + acceptTime;
        }
        return 0;
    }

    // how long the contract has been active.  capped at length of contract
    function elapsedTime() public view returns (uint) {

        if(acceptTime == 0) {
            return 0;
        }
        uint calculatedEndTime = (settleTime == 0) ? now : settleTime;
        uint calculatedElapsedTime = ((calculatedEndTime - acceptTime) > length) ? length : (calculatedEndTime - acceptTime);
        return calculatedElapsedTime;
    }

    function contractExpired() public view returns (bool) {
        return elapsedTime() >= length;
    }

    function contractSettled() public view returns (bool) {
        return settleTime > 0;
    }

    // getter function to check apr of this contract
    function apr() public view returns (uint) {
        return divider(secondsPerYear * interestCollateral, length * principal, 4);
    }


    function earnedInvestorInterest() public view returns (uint) {
        return (elapsedTime() * interestCollateral) / length;
    }

    function investorBalance() public view returns (uint) {

        // contract has started and not yet been settled
        if(acceptTime > 0 && settleTime == 0) {
            return earnedInvestorInterest() + principal;
        }
        return 0;
    }

    function marketMakerBalance() public returns (uint) {
        return compoundBalance() - investorBalance();
    }

    // balance held by this contract on compound
    function compoundBalance() public returns (uint) {
        return (cDaiContract.exchangeRateCurrent() * cDaiContract.balanceOf(address(this))) / 1e18;
    }

    // allows marketMaker to modify this contract if it has not yet been accepted
    function modifyContract(uint _principal, uint _interestCollateral, uint _length) ensureContractNotAccepted ensureOnlyMarketMaker public {
        principal = _principal;
        interestCollateral = _interestCollateral;
        length = _length;
    }

    function acceptContract() ensureContractNotAccepted public {
        // pull in dai from investor
        if (!cDaiContract.transferFrom(msg.sender, cDaiContractAddress, principal)) {
            revert();
        }

        // deposit dai into compound
        if (cDaiContract.mint(principal) != 0) {
            revert();
        }
        acceptTime = now;
    }

    // allows investor to settle the contract and get back their original deposit + interest earned
    function investorSettle() public ensureOnlyInvestor ensureContractAccepted {
        settleTime = now;
        // pull everything out of compound
        if (cDaiContract.redeemUnderlying(compoundBalance()) != 0) {
            revert();
        }
        // transfer investor what they are owed
        if (!daiContract.transfer(investor, investorBalance())) {
            revert();
        }
    }

    // withdraws marketMaker funds if the contract has expired or settled
    function marketMakerWithdraw() public ensureOnlyMarketMaker ensureExpiredOrSettled {
        // pull everything out of compound
        if (cDaiContract.redeemUnderlying(compoundBalance()) != 0) {
            revert();
        }
        // transfer marketMaker what they are owed
        if (!daiContract.transfer(marketMaker, marketMakerBalance())) {
            revert();
        }
    }

    // Transfer interestCollateral from marketMaker to contract and sets terms
    function setupContract(uint _principal, uint _interestCollateral, uint _length) public ensureContractNotAccepted ensureOnlyMarketMaker {
        // pull in dai from market maker
        if (!daiContract.transferFrom(msg.sender, address(this), _interestCollateral)) {
            revert();
        }

        // approve compound to pull from this contract
        daiContract.approve(cDaiContractAddress, _interestCollateral + principal);

        // deposit dai into compound
        if (cDaiContract.mint(_interestCollateral)!=0) {
            revert();
        }

        principal = _principal;
        interestCollateral = _interestCollateral;
        length = _length;
    }

    // included for development purposes to get funds out
    function redeem1(uint amount) public ensureOnlyMarketMaker{
        cDaiContract.redeemUnderlying(amount);
    }
    // included for development purposes to get funds out
    function redeem2(uint amount) public ensureOnlyMarketMaker{
        daiContract.transfer(marketMaker, amount);
    }

    constructor() public {
        marketMaker = address(msg.sender);
    }
}
