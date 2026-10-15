# Soda Machine Match-3 (Godot 4) — Game Specification & Implementation Tasks

> **For Codex CLI:** Build this complete Godot 4 Match-3 Casual Game prototype step-by-step.

## Overview & Game Loop
A Candy Crush style Match-3 game set inside a Vending Machine. The player swaps adjacent soda cans to create matches of 3 or more. Every matched can dispenses money based on its brand profit margin.

## Tech Stack & Engine
- **Engine:** Godot 4.3+ (GDScript 2.0)
- **Display:** Portrait Mobile (1080x1920 viewport, canvas_items stretch)
- **Root Scene:** `res://scenes/Main.tscn`

## Soda Brands & Profit Margins
- **Cola (Red):** $1.50 / can
- **Lemon-Lime (Green):** $2.00 / can
- **Orange Burst (Orange):** $2.50 / can
- **Energy Surge (Blue):** $4.00 / can
- **Craft Kombucha (Purple):** $6.00 / can

## Special Combos
1. **Match 4 in a line:** Creates a **Super Fizz Can** (clears full row or column when matched).
2. **Match 5 in an L or T shape:** Creates a **Restock Crate** (explodes 3x3 surrounding tiles).
3. **Match 5 in a straight line:** Creates a **Golden Can** (swapping with any soda brand clears all cans of that brand from the entire board).

---

## Tasks Breakdown

### Task 1: Project Setup (`project.godot`)
- Setup 1080x1920 portrait resolution with touch emulation enabled.
- Create `GameManager.gd` Autoload for tracking revenue ($), max moves, current moves, target revenue, and streak bonuses.

### Task 2: Soda Can Item (`scenes/SodaCan.tscn` & `scripts/SodaCan.gd`)
- `Area2D` node with collision shape and `Sprite2D` / color tinting for each brand.
- Includes brand type enum (`COLA`, `LEMON_LIME`, `ORANGE`, `ENERGY`, `KOMBUCHA`, `SUPER_FIZZ`, `RESTOCK_CRATE`, `GOLDEN_CAN`).
- Smooth tweening for swap, fall/drop, and dispensing animations.

### Task 3: Match-3 Vending Grid Logic (`scenes/VendingGrid.tscn` & `scripts/VendingGrid.gd`)
- 8x8 Grid with model-view separation.
- Swipe/Drag or Tap-to-Swap adjacent cans.
- Match validation: If no match forms on swap, smoothly animate cans back to original positions.
- Cascade/Gravity logic: Dropping cans fill empty spaces, new cans fall from top.
- Match 4, 5 (L/T), 5 (Line) special can creation.

### Task 4: Economy & Revenue HUD (`scenes/VendingHUD.tscn` & `scripts/VendingHUD.gd`)
- Vending machine frame aesthetics (Top LED display showing Revenue Target `$250.00` and `Moves Remaining`).
- Cash dispensing effect on matches.
- Level Complete & Out-of-Stock (Game Over) Modals with +5 Restock Moves button.

### Task 5: Integration & Headless Test Verification (`tests/test_soda_match3.gd`)
- Assemble `Main.tscn` with `VendingGrid` and `VendingHUD`.
- Write automated test script `tests/test_soda_match3.gd` runnable via `godot --headless --script res://tests/test_soda_match3.gd`.
- Test verifies: valid swap, invalid swap rollback, profit calculation per brand, special can creation, and win/fail conditions.
