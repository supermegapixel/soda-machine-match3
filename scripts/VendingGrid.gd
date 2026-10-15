extends Node2D

signal cash_dispensed(cents: int, at: Vector2)
signal settled
const CanScene = preload("res://scenes/SodaCan.tscn")
const SIZE := 8
const CELL := 118.0
const FIZZ := 5
const CRATE := 6
const GOLD := 7
var board: Array = []
var views: Dictionary = {}
var busy := false
var animation_time := 0.18
var rng := RandomNumberGenerator.new()
var selected := Vector2i(-1, -1)
var press_cell := Vector2i(-1, -1)

func manager():
	return get_node("/root/GameManager")

func _ready() -> void:
	rng.randomize()
	new_board()

func cell(brand: int, special: int = 0, axis: String = "row") -> Dictionary:
	return {"brand": brand, "special": special, "axis": axis}

func inside(p: Vector2i) -> bool:
	return p.x >= 0 and p.y >= 0 and p.x < SIZE and p.y < SIZE

func at(p: Vector2i):
	return board[p.y][p.x]

func put(p: Vector2i, value) -> void:
	board[p.y][p.x] = value

func new_board() -> void:
	board.clear()
	for y in SIZE:
		var row: Array = []
		for x in SIZE:
			var brand := rng.randi_range(0, 4)
			while (x >= 2 and row[x-1].brand == brand and row[x-2].brand == brand) or (y >= 2 and board[y-1][x].brand == brand and board[y-2][x].brand == brand):
				brand = rng.randi_range(0, 4)
			row.append(cell(brand))
		board.append(row)
	if not has_valid_move():
		new_board()
		return
	rebuild_views()

func center(p: Vector2i) -> Vector2:
	return Vector2(p) * CELL + Vector2.ONE * CELL / 2

func rebuild_views() -> void:
	for view in views.values():
		view.queue_free()
	views.clear()
	for y in SIZE:
		for x in SIZE:
			var p := Vector2i(x, y)
			if at(p) == null: continue
			var view = CanScene.instantiate()
			add_child(view)
			view.setup(at(p))
			view.position = center(p)
			views[p] = view

func _draw() -> void:
	for y in SIZE:
		for x in SIZE:
			draw_rect(Rect2(x * CELL + 3, y * CELL + 3, CELL - 6, CELL - 6), Color("14283e"))

func _unhandled_input(event: InputEvent) -> void:
	if busy or manager().state != "playing": return
	var down := false
	var up := false
	var pos := Vector2.ZERO
	if event is InputEventScreenTouch:
		down = event.pressed
		up = not event.pressed
		pos = event.position
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not ProjectSettings.get_setting("input_devices/pointing/emulate_touch_from_mouse", false):
		down = event.pressed
		up = not event.pressed
		pos = event.position
	else: return
	var local := get_global_transform_with_canvas().affine_inverse() * pos
	var p := Vector2i(floori(local.x / CELL), floori(local.y / CELL))
	if down:
		press_cell = p if inside(p) else Vector2i(-1, -1)
	if up and inside(p) and inside(press_cell):
		if p != press_cell:
			if adjacent(press_cell, p): attempt_swap(press_cell, p)
			select_cell(Vector2i(-1, -1))
		elif inside(selected) and adjacent(selected, p):
			var previous := selected
			select_cell(Vector2i(-1, -1))
			attempt_swap(previous, p)
		else:
			select_cell(p)

func select_cell(p: Vector2i) -> void:
	selected = p
	for key in views:
		views[key].selected = key == p
		views[key].queue_redraw()

func adjacent(a: Vector2i, b: Vector2i) -> bool:
	return absi(a.x-b.x) + absi(a.y-b.y) == 1

func exchange(a: Vector2i, b: Vector2i) -> void:
	var old = at(a)
	put(a, at(b))
	put(b, old)

func animate_exchange(a: Vector2i, b: Vector2i) -> void:
	var old = views[a]
	views[a] = views[b]
	views[b] = old
	views[a].travel(center(a), animation_time)
	views[b].travel(center(b), animation_time)

func pause_animation() -> void:
	if animation_time > 0:
		await get_tree().create_timer(animation_time).timeout

# Runs are merged only when they share a cell, making T/L shapes one group.
func find_matches() -> Array:
	var groups: Array = []
	for vertical in [false, true]:
		for line in SIZE:
			var run: Array = []
			var previous := -1
			for offset in range(SIZE + 1):
				var p := Vector2i(line, offset) if vertical else Vector2i(offset, line)
				var brand: int = at(p).brand if offset < SIZE and at(p) != null else -2
				if brand != previous:
					if run.size() >= 3: groups.append(run.duplicate())
					run.clear()
				run.append(p)
				previous = brand
	var merged := true
	while merged:
		merged = false
		for i in groups.size():
			for j in range(i + 1, groups.size()):
				if groups[i].any(func(p): return p in groups[j]):
					for p in groups[j]:
						if p not in groups[i]: groups[i].append(p)
					groups.remove_at(j)
					merged = true
					break
			if merged: break
	return groups

func special_for(group: Array) -> int:
	var same_row: bool = group.all(func(p): return p.y == group[0].y)
	var same_col: bool = group.all(func(p): return p.x == group[0].x)
	if group.size() >= 5: return GOLD if same_row or same_col else CRATE
	if group.size() == 4: return FIZZ
	return 0

func has_valid_move() -> bool:
	for y in SIZE:
		for x in SIZE:
			var a := Vector2i(x,y)
			for delta in [Vector2i.RIGHT, Vector2i.DOWN]:
				var b: Vector2i = a + delta
				if not inside(b): continue
				if at(a).special == GOLD or at(b).special == GOLD: return true
				exchange(a,b)
				var valid := not find_matches().is_empty()
				exchange(a,b)
				if valid: return true
	return false

func attempt_swap(a: Vector2i, b: Vector2i) -> bool:
	if busy or not inside(a) or not inside(b) or not adjacent(a,b) or manager().state != "playing": return false
	busy = true
	exchange(a,b)
	animate_exchange(a,b)
	await pause_animation()
	var groups := find_matches()
	var forced: Array = []
	if at(a).special == GOLD or at(b).special == GOLD:
		var both: bool = at(a).special == GOLD and at(b).special == GOLD
		var brand: int = at(b).brand if at(a).special == GOLD else at(a).brand
		for y in SIZE:
			for x in SIZE:
				var p := Vector2i(x,y)
				if both or at(p).brand == brand or p == a or p == b: forced.append(p)
	if groups.is_empty() and forced.is_empty():
		exchange(a,b)
		animate_exchange(a,b)
		await pause_animation()
		busy = false
		return false
	manager().begin_move()
	await resolve(groups, forced, b)
	manager().finish_move()
	if manager().state == "playing" and not has_valid_move(): new_board()
	busy = false
	settled.emit()
	return true

func expanded_clear(initial: Array) -> Array:
	var clear := initial.duplicate()
	var index := 0
	while index < clear.size():
		var p: Vector2i = clear[index]
		index += 1
		var data = at(p)
		if data == null: continue
		var affected: Array = []
		if data.special == FIZZ:
			for n in SIZE: affected.append(Vector2i(n,p.y) if data.axis == "row" else Vector2i(p.x,n))
		elif data.special == CRATE:
			for dy in range(-1,2):
				for dx in range(-1,2): affected.append(p + Vector2i(dx,dy))
		elif data.special == GOLD:
			for y in SIZE:
				for x in SIZE:
					var q := Vector2i(x,y)
					if at(q) != null and at(q).brand == data.brand: affected.append(q)
		for q in affected:
			if inside(q) and q not in clear: clear.append(q)
	return clear

func resolve(groups: Array, forced: Array = [], preferred: Vector2i = Vector2i(-1,-1)) -> void:
	var cascade := 1
	while not groups.is_empty() or not forced.is_empty():
		var clear: Array = forced.duplicate()
		var creations: Dictionary = {}
		for group in groups:
			for p in group:
				if p not in clear: clear.append(p)
			var kind := special_for(group)
			if kind != 0:
				var anchor: Vector2i = preferred if preferred in group else group[group.size()/2]
				creations[anchor] = cell(at(anchor).brand, kind, "row" if group[0].y == group[1].y else "column")
		clear = expanded_clear(clear)
		var brands: Array = []
		for p in clear:
			if at(p) == null: continue
			brands.append(at(p).brand)
			put(p, null)
			views[p].dispense(animation_time)
		var earned: int = manager().award(brands, cascade)
		cash_dispensed.emit(earned, center(clear[0]))
		await pause_animation()
		for p in clear:
			if views.has(p):
				views[p].queue_free()
				views.erase(p)
		for p in creations:
			put(p, creations[p])
			var view = CanScene.instantiate()
			add_child(view)
			view.setup(at(p))
			view.position = center(p)
			views[p] = view
		await collapse()
		groups = find_matches()
		forced = []
		preferred = Vector2i(-1,-1)
		cascade += 1

func collapse() -> void:
	for x in SIZE:
		var write := SIZE - 1
		for y in range(SIZE - 1, -1, -1):
			var source := Vector2i(x,y)
			if at(source) == null: continue
			var dest := Vector2i(x,write)
			if source != dest:
				put(dest, at(source))
				put(source,null)
				views[dest] = views[source]
				views.erase(source)
				views[dest].travel(center(dest), animation_time)
			write -= 1
		for y in range(write, -1, -1):
			var p := Vector2i(x,y)
			put(p,cell(rng.randi_range(0,4)))
			var view = CanScene.instantiate()
			add_child(view)
			view.setup(at(p))
			view.position = center(Vector2i(x,y-write-1))
			view.travel(center(p),animation_time)
			views[p] = view
	await pause_animation()
