extends CanvasLayer

var revenue_label: Label
var moves_label: Label
var modal: PanelContainer
var title: Label
var restock_button: Button
var manager: Node

func label(text: String, size: int, color: Color = Color.WHITE) -> Label:
	var result := Label.new()
	result.text = text
	result.add_theme_font_size_override("font_size", size)
	result.add_theme_color_override("font_color", color)
	result.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return result

func panel(rect: Rect2, color: Color) -> PanelContainer:
	var result := PanelContainer.new()
	result.position = rect.position
	result.size = rect.size
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(24)
	style.set_border_width_all(4)
	style.border_color = Color("42617e")
	result.add_theme_stylebox_override("panel", style)
	add_child(result)
	return result

func _ready() -> void:
	manager = get_node("/root/GameManager")
	var header := panel(Rect2(50, 60, 980, 340), Color("102236"))
	var stack := VBoxContainer.new()
	stack.alignment = BoxContainer.ALIGNMENT_CENTER
	header.add_child(stack)
	stack.add_child(label("SODA / STATION", 60, Color("f7cb66")))
	stack.add_child(label("MATCH • DISPENSE • PROFIT", 24, Color("8eb0c7")))
	revenue_label = label("", 39, Color("87f3c2"))
	stack.add_child(revenue_label)
	moves_label = label("", 32)
	stack.add_child(moves_label)
	var footer := panel(Rect2(50, 1450, 980, 350), Color("102236"))
	var info := VBoxContainer.new()
	info.alignment = BoxContainer.ALIGNMENT_CENTER
	footer.add_child(info)
	info.add_child(label("SWAP CANS. STACK CASH.", 36, Color("f7cb66")))
	info.add_child(label("Tap two neighbors or swipe to match 3+", 28))
	info.add_child(label("4 → Fizz   •   T / L → Crate   •   5 → Gold", 27))
	info.add_child(label("Cola $1.50 • Lime $2 • Orange $2.50", 25, Color("8eb0c7")))
	info.add_child(label("Energy $4 • Kombucha $6", 25, Color("8eb0c7")))
	info.add_child(label("Cascade streaks earn +25% per step", 25, Color("87f3c2")))
	modal = panel(Rect2(100, 650, 880, 490), Color("19314b"))
	modal.mouse_filter = Control.MOUSE_FILTER_STOP
	var content := VBoxContainer.new()
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 30)
	modal.add_child(content)
	title = label("", 54, Color("f7cb66"))
	content.add_child(title)
	restock_button = Button.new()
	restock_button.text = "+5 Restock Moves"
	restock_button.add_theme_font_size_override("font_size", 36)
	restock_button.pressed.connect(func(): manager.restock())
	content.add_child(restock_button)
	var restart := Button.new()
	restart.text = "New Machine"
	restart.add_theme_font_size_override("font_size", 32)
	restart.pressed.connect(func():
		manager.reset()
		get_tree().reload_current_scene())
	content.add_child(restart)
	manager.changed.connect(refresh)
	get_parent().get_node("VendingGrid").cash_dispensed.connect(cash_effect)
	refresh()

func refresh() -> void:
	revenue_label.text = "$%.2f  /  $%.2f TARGET" % [manager.revenue, manager.target_revenue]
	moves_label.text = "%d MOVES REMAINING   •   STREAK ×%d" % [manager.current_moves, maxi(1,manager.streak)]
	modal.visible = manager.state != "playing"
	title.text = "LEVEL COMPLETE!" if manager.state == "won" else "OUT OF STOCK"
	restock_button.visible = manager.state == "lost"

func cash_effect(cents: int, at: Vector2) -> void:
	var cash := label("+$%.2f" % (cents / 100.0), 44, Color("87f3c2"))
	add_child(cash)
	cash.position = at + get_parent().get_node("VendingGrid").position - Vector2(40,0)
	cash.z_index = 10
	var tween := create_tween().set_parallel()
	tween.tween_property(cash, "position:y", cash.position.y - 160, 0.85)
	tween.tween_property(cash, "modulate:a", 0.0, 0.85)
	tween.chain().tween_callback(cash.queue_free)
