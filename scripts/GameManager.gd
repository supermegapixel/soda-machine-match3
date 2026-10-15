extends Node

signal changed
signal level_complete
signal out_of_stock

const PROFITS := [150, 200, 250, 400, 600]
var level: int = 1
var starting_moves: int = 25
var max_moves: int = 25
var current_moves: int = 25
var target_cents: int = 25000
var revenue_cents: int = 0
var streak: int = 0
var state: String = "playing"
var revenue: float:
	get: return revenue_cents / 100.0
var target_revenue: float:
	get: return target_cents / 100.0

func reset(moves: int = 25, target: int = 25000) -> void:
	level = 1
	starting_moves = moves
	max_moves = moves
	current_moves = moves
	target_cents = target
	revenue_cents = 0
	streak = 0
	state = "playing"
	changed.emit()

func next_level() -> bool:
	if state != "won":
		return false
	var rollover_moves := current_moves
	var overage_bonus_moves := maxi(0, revenue_cents - target_cents) / 10000
	level += 1
	target_cents = roundi(target_cents * 1.15)
	var base_level_moves := 25
	max_moves = base_level_moves + rollover_moves + overage_bonus_moves
	current_moves = max_moves
	revenue_cents = 0
	streak = 0
	state = "playing"
	changed.emit()
	return true

# Level one is uniform; each level increasingly favors cheaper brands.
func brand_weights() -> Array[float]:
	var weights: Array[float] = []
	var difficulty := float(level - 1) / float(level + 3)
	for brand in PROFITS.size():
		weights.append(1.0 + difficulty * (4 - brand))
	return weights

func begin_move() -> bool:
	if state != "playing" or current_moves <= 0:
		return false
	current_moves -= 1
	streak = 0
	changed.emit()
	return true

func award(brands: Array, cascade: int) -> int:
	var earned := 0
	for brand in brands:
		earned += PROFITS[int(brand)]
	streak = cascade
	# Each successive cascade adds 25% of base profit.
	earned = earned * (4 + maxi(0, cascade - 1)) / 4
	revenue_cents += earned
	changed.emit()
	return earned

func finish_move() -> void:
	if state != "playing":
		return
	if revenue_cents >= target_cents:
		state = "won"
		get_node("/root/SoundManager").play_win()
		level_complete.emit()
	elif current_moves <= 0:
		state = "lost"
		get_node("/root/SoundManager").play_loss()
		out_of_stock.emit()
	changed.emit()

func restock() -> void:
	if state != "lost":
		return
	revenue_cents = int(revenue_cents * 0.90)
	current_moves += 5
	state = "playing"
	changed.emit()
