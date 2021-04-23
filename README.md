Repository for WIF Bet Handler

# Bet Handler workflow

## Place Bet
1. User calls `placeBet()` providing direction and amount.
2. BetHandler transfer specified amount of stablecoins (BUSD)
3. Event `BetPlaced` is emitted and should be handled by exchange bot.
4. Bot opens market position placing required orders
5. Bot calls `betAccepted()` specifying actual start price and target prices
6. If bot is unable to open position, it should call `betCanceled()`

## Bet result
1. When Take-Profit or Stop-Loss are executed or when position is closed because 5 day passed, bot should call `betWon()` or `betLost()` depending on close price.
   - If Bet Direction is UP and close price is higher then open price, Bot should call `betWon()` providing amount to pay to user
   - If Bet Direction is UP and close price is lower then open price, Bot should call `betLost()` providing amount to pay to user, if any
   - If Bet Direction is DOWN and close price is lower then open price, Bot should call `betWon()` providing amount to pay to user
   - If Bet Direction is DOWN and close price is higher then open price, Bot should call `betLost()` providing amount to pay to user, if any
2. Handling `betWon()` or `betLost()` BetHandler sends a prize or partial refund to the user.

