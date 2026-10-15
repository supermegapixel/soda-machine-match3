extends SceneTree

const Grid = preload("res://scripts/VendingGrid.gd")
var failures := 0
var checks := 0
var grid
var manager

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error("FAIL: " + message)
	else:
		print("PASS: " + message)

func fixture() -> void:
	grid.rng.seed = 12345
	grid.board = []
	for y in 8:
		var row: Array = []
		for x in 8: row.append(grid.cell((x + 2*y) % 5))
		grid.board.append(row)
	grid.rebuild_views()
	manager.reset()

func set_brand(x: int, y: int, brand: int) -> void:
	grid.put(Vector2i(x,y), grid.cell(brand))

func run() -> void:
	manager = root.get_node("GameManager")
	grid = Grid.new()
	root.add_child(grid)
	grid.animation_time = 0.0
	grid.rng.seed = 12345
	check(grid.board.size() == 8 and grid.views.size() == 64, "8x8 board and views")
	check(grid.find_matches().is_empty(), "initial board has no automatic matches")
	check(grid.has_valid_move(), "initial board has a playable move")
	for brand in 5:
		manager.reset()
		var earned: int = manager.award([brand],1)
		check(earned == [150,200,250,400,600][brand], "profit for brand %d" % brand)
	manager.reset()
	check(manager.award([0,1,2,3,4],1) == 1600, "mixed brand profit")
	check(manager.award([1],2) == 250, "cascade bonus")
	fixture()
	var original: Array = grid.board.duplicate(true)
	check(not await grid.attempt_swap(Vector2i(0,0),Vector2i(1,0)), "invalid swap rejected")
	check(grid.board == original and manager.current_moves == 25, "invalid swap rolls back without spending moves")
	check(not await grid.attempt_swap(Vector2i(0,0),Vector2i(3,0)), "non-adjacent swap rejected")
	fixture()
	# Swap the cola in row 1 into the gap between two colas in row 0.
	set_brand(0,0,0)
	set_brand(1,0,1)
	set_brand(2,0,0)
	set_brand(1,1,0)
	grid.rebuild_views()
	check(grid.find_matches().is_empty(), "valid swap fixture starts settled")
	check(await grid.attempt_swap(Vector2i(1,1),Vector2i(1,0)), "valid swap resolves")
	check(manager.current_moves == 24 and manager.revenue_cents >= 450, "valid swap spends one move and awards profit")
	check(grid.find_matches().is_empty() and grid.views.size() == 64, "cascades finish with full settled board")
	for kind in [5,6,7]:
		fixture()
		var points: Array = []
		if kind == 6:
			points = [Vector2i(1,1),Vector2i(2,1),Vector2i(3,1),Vector2i(2,0),Vector2i(2,2)]
		else:
			for x in (4 if kind == 5 else 5): points.append(Vector2i(x,0))
		for p in points: set_brand(p.x,p.y,0)
		grid.rebuild_views()
		var groups: Array = grid.find_matches()
		check(groups.size() == 1 and grid.special_for(groups[0]) == kind, "recognize special pattern %d" % kind)
		await grid.resolve(groups,[],points[0])
		var found := false
		for row in grid.board:
			for data in row:
				if data.special == kind: found = true
		check(found, "create special can %d" % kind)
	fixture()
	var l_shape: Array = [Vector2i(0,0),Vector2i(1,0),Vector2i(2,0),Vector2i(0,1),Vector2i(0,2)]
	for p in l_shape: set_brand(p.x,p.y,4)
	check(grid.special_for(grid.find_matches()[0]) == 6, "L shape produces crate")
	fixture()
	grid.put(Vector2i(3,3),grid.cell(0,5,"row"))
	check(grid.expanded_clear([Vector2i(3,3)]).size() == 8, "fizz clears full row")
	grid.put(Vector2i(3,3),grid.cell(0,5,"column"))
	check(grid.expanded_clear([Vector2i(3,3)]).size() == 8, "fizz clears full column")
	grid.put(Vector2i(3,3),grid.cell(0,6))
	check(grid.expanded_clear([Vector2i(3,3)]).size() == 9, "crate clears 3x3")
	grid.put(Vector2i(0,0),grid.cell(0,6))
	check(grid.expanded_clear([Vector2i(0,0)]).size() == 4, "crate clips at board edge")
	fixture()
	grid.put(Vector2i(0,0),grid.cell(0,7))
	grid.rebuild_views()
	var expected := 0
	for row in grid.board:
		for data in row:
			if data.brand == 1: expected += 200
	check(await grid.attempt_swap(Vector2i(0,0),Vector2i(1,0)), "gold swaps with any brand")
	check(manager.revenue_cents >= expected + 150, "gold awards all target brand cans")
	manager.reset(1,150)
	manager.begin_move()
	manager.award([0],1)
	manager.finish_move()
	check(manager.state == "won", "target reached on last move wins")
	manager.reset(1,25000)
	manager.begin_move()
	manager.finish_move()
	check(manager.state == "lost", "moves exhausted triggers out of stock")
	manager.revenue_cents = 12349
	manager.restock()
	check(manager.revenue_cents == 11114, "restock deducts ten percent and truncates fractional cents")
	manager.restock()
	check(manager.revenue_cents == 11114 and manager.current_moves == 5, "restock during play does not charge or grant moves")
	check(manager.state == "playing" and manager.current_moves == 5, "restock grants five moves")
	fixture()
	grid.animation_time = 0.01
	original = grid.board.duplicate(true)
	check(not await grid.attempt_swap(Vector2i(0,0),Vector2i(1,0)), "animated invalid swap rejects")
	check(grid.board == original and grid.views[Vector2i(0,0)].position.is_equal_approx(grid.center(Vector2i(0,0))), "animated rollback restores view and model")
	set_brand(0,0,0)
	set_brand(1,0,1)
	set_brand(2,0,0)
	set_brand(1,1,0)
	grid.rebuild_views()
	check(await grid.attempt_swap(Vector2i(1,1),Vector2i(1,0)), "animated swap and gravity finish")
	var aligned := true
	for p in grid.views:
		if not grid.views[p].position.is_equal_approx(grid.center(p)): aligned = false
	check(aligned and not grid.busy, "all animated views align with board")
	grid.animation_time = 0.0
	fixture()
	grid.put(Vector2i(2,2),grid.cell(0,5,"row"))
	grid.put(Vector2i(4,2),grid.cell(0,5,"column"))
	check(grid.expanded_clear([Vector2i(2,2)]).size() == 15, "special effects chain without double counting")
	fixture()
	var shaken = grid.cell(0)
	grid.mark_fall(shaken, 4)
	check(shaken.shaken_at == -1, "four-space fall does not shake a can")
	grid.mark_fall(shaken, 5)
	check(grid.is_shaken(shaken), "five-space fall timestamps and shakes a can")
	var stamp: int = shaken.shaken_at
	check(grid.is_shaken(shaken, stamp + 29999), "shaken can is active just before 30 seconds")
	check(not grid.is_shaken(shaken, stamp + 30000), "shaken can expires at 30000 milliseconds")
	grid.mark_fall(shaken, 2)
	check(shaken.shaken_at == stamp, "short fall preserves original shaken timestamp")
	shaken.shaken_at = 0
	grid.mark_fall(shaken, 5)
	check(grid.is_shaken(shaken), "another long fall refreshes shaken status")
	grid.put(Vector2i(3,3), shaken)
	grid.rebuild_views()
	check(grid.views[Vector2i(3,3)].shaken_visible, "shaken can view displays badge")
	var cross: Array = grid.expanded_clear([Vector2i(3,3)])
	var full_cross := cross.size() == 15
	for n in 8:
		full_cross = full_cross and Vector2i(n,3) in cross and Vector2i(3,n) in cross
	check(full_cross, "shaken clear includes entire row and column exactly once")
	grid.put(Vector2i(6,3), grid.cell(1))
	grid.mark_fall(grid.at(Vector2i(6,3)), 5)
	check(grid.expanded_clear([Vector2i(3,3)]).size() == 22, "cross explosions trigger other shaken cans")
	grid.put(Vector2i(6,3), grid.cell(1,5,"column"))
	check(grid.expanded_clear([Vector2i(3,3)]).size() == 22, "cross explosion chains special cans")
	fixture()
	shaken = grid.cell(0)
	grid.mark_fall(shaken, 5)
	grid.put(Vector2i(0,0), shaken)
	check(grid.expanded_clear([Vector2i(0,0)]).size() == 15, "corner cross still clears full row and column")
	# A five-space gap shakes survivors and incoming refill cans.
	fixture()
	var falling = grid.at(Vector2i(0,2))
	for y in range(3,8): grid.put(Vector2i(0,y), null)
	grid.rebuild_views()
	await grid.collapse()
	check(grid.at(Vector2i(0,7)) == falling and grid.is_shaken(falling), "collapse shakes surviving can falling five spaces")
	check(grid.is_shaken(grid.at(Vector2i(0,0))) and grid.views[Vector2i(0,0)].shaken_visible, "five-space refill fall shakes new cans and updates badge")
	fixture()
	for y in range(4,8): grid.put(Vector2i(0,y), null)
	grid.rebuild_views()
	await grid.collapse()
	check(not grid.is_shaken(grid.at(Vector2i(0,7))) and not grid.is_shaken(grid.at(Vector2i(0,0))), "four-space collapse leaves survivors and refill cans unshaken")
	fixture()
	# Capture the first award to verify a matched shaken can clears its cross in one batch.
	for x in 3: set_brand(x,3,0)
	grid.mark_fall(grid.at(Vector2i(1,3)), 5)
	grid.rebuild_views()
	var awards: Array = []
	var capture = func(cents, _at): awards.append(cents)
	grid.cash_dispensed.connect(capture)
	var expected_cross_profit := 0
	for y in 8:
		for x in 8:
			if y == 3 or x == 1: expected_cross_profit += manager.PROFITS[grid.at(Vector2i(x,y)).brand]
	await grid.resolve([[Vector2i(0,3),Vector2i(1,3),Vector2i(2,3)]])
	grid.cash_dispensed.disconnect(capture)
	check(awards[0] == expected_cross_profit, "matched shaken can awards its full cross simultaneously without duplicates")
	fixture()
	for y in 5: set_brand(0,y,3)
	check(grid.special_for(grid.find_matches()[0]) == 7, "vertical five creates gold")
	manager.reset()
	check(not manager.next_level() and manager.level == 1, "cannot advance unfinished level")
	manager.current_moves = 0
	manager.revenue_cents = manager.target_cents
	manager.state = "won"
	check(manager.next_level(), "completed level advances")
	check(manager.level == 2 and manager.target_cents == 28750, "next target increases by 15 percent")
	check(manager.current_moves == 25 and manager.max_moves == 25 and manager.revenue_cents == 0 and manager.streak == 0 and manager.state == "playing", "next level resets round with 25 base moves")
	manager.state = "won"
	manager.next_level()
	check(manager.target_cents == 33063, "target growth compounds with cent rounding")
	for n in 30:
		manager.current_moves = 0
		manager.state = "won"
		manager.next_level()
	check(manager.max_moves == 25 and manager.current_moves == 25, "base move allowance remains 25 at high levels")
	for overage in [0, 9999, 10000, 19999, 20000, 29999]:
		manager.reset()
		manager.current_moves = 7
		manager.revenue_cents = manager.target_cents + overage
		manager.finish_move()
		check(manager.next_level(), "won level with overage %d advances" % overage)
		var expected_moves: int = 25 + 7 + overage / 10000
		check(manager.current_moves == expected_moves and manager.max_moves == expected_moves, "rollover and full $100 bonuses for overage %d" % overage)
		check(manager.revenue_cents == 0, "overage revenue resets on next level")
	manager.current_moves = 3
	manager.revenue_cents = manager.target_cents
	manager.finish_move()
	manager.next_level()
	check(manager.current_moves == 28, "following level uses its base plus only remaining moves")
	manager.reset()
	check(manager.current_moves == 25 and manager.max_moves == 25, "reset clears carried moves and bonuses")
	manager.reset(16)
	manager.level = 10
	manager.current_moves = 4
	manager.revenue_cents = manager.target_cents + 10000
	manager.finish_move()
	manager.next_level()
	check(manager.current_moves == 30, "rollover and bonus add to fixed 25 base moves")
	var weights: Array = manager.brand_weights()
	check(weights[0] > weights[1] and weights[1] > weights[2] and weights[2] > weights[3] and weights[3] > weights[4] and weights[4] > 0, "higher levels favor lower profit brands with all brands available")
	grid.rng.seed = 789
	var counts := [0, 0, 0, 0, 0]
	for n in 20000:
		counts[grid.random_brand()] += 1
	check(counts[0] > counts[1] and counts[1] > counts[2] and counts[2] > counts[3] and counts[3] > counts[4], "weighted sampler favors cheap sodas")
	grid.new_board()
	check(grid.find_matches().is_empty() and grid.has_valid_move(), "weighted level board starts settled and playable")
	manager.reset()
	check(manager.level == 1 and manager.brand_weights() == [1.0, 1.0, 1.0, 1.0, 1.0], "new machine resets progression and spawn weights")
	var sound = root.get_node("SoundManager")
	for kind in ["swap", "match", "explosion", "win", "loss"]:
		var stream = sound.sounds[kind]
		check(stream is AudioStreamWAV and stream.format == AudioStreamWAV.FORMAT_16_BITS and stream.mix_rate == 22050 and not stream.data.is_empty(), "procedural WAV for " + kind)
	check(sound.match_pitch(1) == 1.0 and sound.match_pitch(2) > sound.match_pitch(1) and sound.match_pitch(3) > sound.match_pitch(2), "cascade cash register pitch escalates")
	for n in 30:
		sound.play_match(n + 1)
	check(sound.voices.size() <= sound.MAX_VOICES, "audio voices stay bounded during cascades")
	# Instantiate the full scene as a smoke test of HUD wiring and resources.
	var main = load("res://scenes/Main.tscn").instantiate()
	root.add_child(main)
	check(main.get_node("VendingHUD").revenue_label.text.contains("250.00"), "main scene HUD shows target")
	var hud = main.get_node("VendingHUD")
	check(hud.restock_button.text == "+5 Restock Moves (-10% Revenue)", "restock button shows revenue cost")
	check(not hud.next_level_button.visible, "next level hidden during play")
	manager.revenue_cents = manager.target_cents
	manager.finish_move()
	check(hud.next_level_button.visible and not hud.restock_button.visible, "win displays Next Level button")
	hud.next_level_button.pressed.emit()
	check(manager.level == 2 and not hud.modal.visible and hud.moves_label.text.contains("LEVEL 2"), "Next Level button advances and refreshes HUD")
	check(main.get_node("VendingGrid").views.size() == 64 and main.get_node("VendingGrid").find_matches().is_empty(), "Next Level button builds fresh settled board")
	sound.stop_all()
	await create_timer(0.1).timeout
	main.queue_free()
	grid.queue_free()
	await process_frame
	print("%d checks; %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
