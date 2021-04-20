// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract BetHandler is AccessControl, Pausable {
    using SafeERC20 for IERC20;
    using Counters for Counters.Counter;

    bytes32 public constant FUNDS_MANAGER_ROLE = keccak256("FUNDS_MANAGER_ROLE");
    bytes32 public constant MARKET_MANAGER_ROLE = keccak256("MARKET_MANAGER_ROLE");
    uint256 private constant EXP = 1e18;

    enum Direction {UP, DOWN}

    enum State {
        NEW,            // Bet is registreted in smart contract (this is also state of not yet placed bets, for them bet.user == address(0))
        ACCEPTED,       // Bet is executed by Binance Bot
        CANCEL,         // Bet can not be executed and should be returned
        WIN,            // Bet closed and user wins something
        LOSE            // Bet closed and user lost part of his money
    }

    event BetPlaced(uint256 indexed id, address indexed user, Direction direction, uint256 amount);
    event BetAccepted(uint256 indexed id, uint256 startPrice, uint256 winPrice, uint256 losePrice);
    event BetWon(uint256 indexed id, uint256 closePrice);
    event BetLost(uint256 indexed id, uint256 closePrice);
    event BetCanceled(uint256 indexed id);

    struct Bet {
        address user;
        uint256 acceptedTimestamp;
        Direction direction;
        uint256 amount;
        State state;
    }

    IERC20 public token;    // Token accepted as payment
    Counters.Counter public nextBetId;
    mapping(uint256=>Bet) public bets;

    modifier onlyAdmin(){
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "!admin");
        _;
    }

    modifier onlyFundsManager(){
        require(hasRole(FUNDS_MANAGER_ROLE, _msgSender()), "!funds manager");
        _;
    }

    modifier onlyMarketManager(){
        require(hasRole(FUNDS_MANAGER_ROLE, _msgSender()), "!market manager");
        _;
    }

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(FUNDS_MANAGER_ROLE, _msgSender());
        _setupRole(MARKET_MANAGER_ROLE, _msgSender());
        nextBetId.increment();                          // Make valid ids starting from 1
    }

    function placeBet(Direction direction, uint256 amount) external whenNotPaused {
        token.safeTransferFrom(_msgSender(), address(this), amount);

        uint256 betId = nextBetId.current();
        nextBetId.increment(); 
        bets[betId] = Bet({
            user: _msgSender(),
            acceptedTimestamp: 0,
            direction: direction,
            amount: amount,
            state: State.NEW
        });

        emit BetPlaced(betId, _msgSender(), direction, amount);
    }

    function betAccepted(uint256 betId, uint256 startPrice, uint256 winPrice, uint256 losePrice) external onlyMarketManager {
        Bet storage bet = bets[betId];
        require(bet.state == State.NEW, "wrong bet state");

        bet.state = State.ACCEPTED;
        emit BetAccepted(betId, startPrice, winPrice, losePrice);
    }

    function betCanceled(uint256 betId) external onlyMarketManager {
        Bet storage bet = bets[betId];
        require(bet.state == State.ACCEPTED, "wrong bet state");

        bet.state = State.CANCEL;

        payout(bet.user, bet.amount);
        emit BetCanceled(betId);
    }

    function betWon(uint256 betId, uint256 closePrice, uint256 winAmount) external onlyMarketManager {
        Bet storage bet = bets[betId];
        require(bet.state == State.ACCEPTED, "wrong bet state");

        bet.state = State.WIN;
        
        // TODO better validate winAmount
        require( (winAmount >= bet.amount) && (winAmount <= (bet.amount * 2)), "wrong win");

        payout(bet.user, winAmount);
        emit BetWon(betId, closePrice);
    }

    function betLost(uint256 betId, uint256 closePrice, uint256 refundAmount) external onlyMarketManager {
        Bet storage bet = bets[betId];
        require(bet.state == State.ACCEPTED, "wrong bet state");

        bet.state = State.LOSE;

        // TODO better validate refundAmount
        require(refundAmount <= bet.amount, "wrong refund");

        payout(bet.user, refundAmount);
        emit BetLost(betId, closePrice);
    }

    function pruneBets(uint256 from, uint256 to) external onlyAdmin {
        // TODO implement bets pruning
    }

    function setToken(IERC20 _token) external onlyAdmin {
        token = _token;
    }

    function pause() external onlyAdmin {
        _pause();
    }

    function unpause() external onlyAdmin {
        _unpause();
    }

    function payout(address user, uint256 amount) internal {
        // TODO implement payout queue
        token.transfer(user, amount); 
    }


}