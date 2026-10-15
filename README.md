# Soda Machine Match-3

Godot 4.3+ portrait game. Open `project.godot` and run the main scene, or run `godot --path .`.

Tap adjacent cans or drag one onto its neighbor. Match at least three to earn each can's brand profit. Invalid swaps return without using a move. Successive cascades add 25% of base profit per step. Start by reaching $250 within 25 moves; out-of-stock machines can restock five moves. After a win, choose Next Level: targets compound by 15% (rounded to cents), moves decrease by one per level to a minimum of 15, and spawning increasingly favors cheaper sodas. New Machine resets progression.

Four in a line creates a Fizz can that clears along that line when matched. T/L matches create a 3×3 crate. Five in a line creates a golden can; swap it with any brand to clear that brand. Two golden cans clear the board. Special effects chain, and boards without possible moves automatically restock without charging a move.

The board stores brand, special type, and direction separately from animated can nodes. All money is tracked in cents. Visuals are drawn in Godot, and SoundManager synthesizes WAV effects for swaps, cash register matches with rising cascade pitch, special explosions, wins, and losses; no external assets or plugins are required.

Run verification:

```sh
godot --headless --script res://tests/test_soda_match3.gd
```

In a sandbox that disallows Godot's default user-data directory, prefix the command with `XDG_DATA_HOME=/tmp/soda-match3-data`.
