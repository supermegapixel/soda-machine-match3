extends Node

signal changed
signal level_complete
signal out_of_stock

const PROFITS := [150, 200, 250, 400, 600]
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
	max_moves = moves
	current_moves = moves
	target_cents = target
	revenue_cents = 0
	streak = 0
	state = "playing"
	changed.emit()

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
	if revenue_cents >= target_cents:
		state = "won"
		level_complete.emit()
	elif current_moves <= 0:
		state = "lost"
		out_of_stock.emit()
	changed.emit()

func restock() -> void:
	if state != "lost":
		return
	current_moves += 5
	state = "playing"
	changed.emit()
