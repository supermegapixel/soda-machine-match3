extends Area2D

enum Brand { COLA, LEMON_LIME, ORANGE, ENERGY, KOMBUCHA, SUPER_FIZZ, RESTOCK_CRATE, GOLDEN_CAN }
const COLORS := [Color("eb475d"), Color("6ed985"), Color("ffad4b"), Color("51b9f4"), Color("b38af0")]
const NAMES := ["COLA", "LIME", "ORANGE", "ENERGY", "KOMBUCHA"]
var brand: int = 0
var special: int = 0
var selected := false

func setup(data: Dictionary) -> void:
	brand = data.brand
	special = data.special
	queue_redraw()

func _draw() -> void:
	if selected:
		draw_style_box(_box(Color("fff4a8"), 18), Rect2(-51, -57, 102, 114))
	draw_style_box(_box(COLORS[brand].darkened(0.3), 15), Rect2(-43, -50, 86, 103))
	draw_style_box(_box(COLORS[brand], 14), Rect2(-43, -53, 86, 98))
	draw_style_box(_box(Color("dce8ed"), 7), Rect2(-37, -53, 74, 12))
	draw_line(Vector2(-24, -29), Vector2(-24, 22), Color(1, 1, 1, 0.3), 6)
	var caption: String = NAMES[brand]
	if special == Brand.SUPER_FIZZ: caption = "FIZZ"
	if special == Brand.RESTOCK_CRATE: caption = "3 x 3"
	if special == Brand.GOLDEN_CAN: caption = "GOLD"
	if special != 0:
		draw_circle(Vector2(0, 0), 30, Color("f6d16b"))
	draw_string(ThemeDB.fallback_font, Vector2(-34, 6), caption, HORIZONTAL_ALIGNMENT_CENTER, 68, 15, Color("102034"))

func _box(color: Color, radius: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.set_corner_radius_all(radius)
	return box

func travel(destination: Vector2, duration: float) -> void:
	if duration <= 0:
		position = destination
		return
	var tween := create_tween()
	tween.tween_property(self, "position", destination, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func dispense(duration: float) -> void:
	if duration <= 0: return
	var tween := create_tween().set_parallel()
	tween.tween_property(self, "scale", Vector2(0.1, 0.1), duration)
	tween.tween_property(self, "modulate:a", 0.0, duration)
	tween.tween_property(self, "position:y", position.y + 100, duration)
