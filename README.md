# Soda Machine Match-3

Godot 4.3+ portrait game. Open `project.godot` and run the main scene, or run `godot --path .`.

Tap adjacent cans or drag one onto its neighbor. Match at least three to earn each can's brand profit. Invalid swaps return without using a move. Successive cascades add 25% of base profit per step. Start by reaching $250 within 25 moves; out-of-stock machines can buy five restock moves for 10% of current revenue (the remaining revenue is truncated to whole cents). After a win, choose Next Level: targets compound by 15% (rounded to cents), base starting moves stay at 25 for every level, and spawning increasingly favors cheaper sodas. Unused moves from a won level roll over, and every full $100 (10000 cents) earned over that level’s target adds one bonus move for the next level. The next level starts with base moves + unused moves + over-target bonus moves; revenue resets to zero. New Machine resets progression and all carried moves.

Four in a line creates a Fizz can that clears along that line when matched. T/L matches create a 3×3 crate. Five in a line creates a golden can; swap it with any brand to clear that brand. Two golden cans clear the board. Any can (including a refill or special can) falling more than four grid spaces in one collapse becomes shaken, marked by a yellow + badge. Matching or clearing it within 30 seconds of that fall triggers a Cross Explosion clearing its entire row and column together. Another qualifying fall refreshes the timestamp; shorter falls and swaps do not. Cross Explosions chain with other shaken cans and specials, with each can counted once. Special effects chain, and boards without possible moves automatically restock without charging a move.

The board stores brand, special type, direction, and shaken timestamps separately from animated can nodes. All money is tracked in cents. Visuals are drawn in Godot, and SoundManager synthesizes WAV effects for swaps, cash register matches with rising cascade pitch, special explosions, wins, and losses; no external assets or plugins are required.

Run verification:

```sh
godot --headless --script res://tests/test_soda_match3.gd
```

In a sandbox that disallows Godot's default user-data directory, prefix the command with `XDG_DATA_HOME=/tmp/soda-match3-data`.
