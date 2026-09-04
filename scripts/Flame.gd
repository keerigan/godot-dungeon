class_name Flame
extends Node2D

## Petite flamme animée dessinée sur les torches (au-dessus de la lumière).
## Teinte adaptée au thème courant.

var tint := Color(1.0, 0.7, 0.4)
var _t := 0.0


func _ready() -> void:
	_t = randf() * 10.0


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	var flicker := 1.0 + sin(_t * 12.0) * 0.12 + sin(_t * 23.0) * 0.06
	var h := 17.0 * flicker
	# Flamme externe (couleur de la torche)
	_flame(h, 7.0 * flicker, Color(tint.r, tint.g * 0.7, tint.b * 0.5, 0.9))
	# Cœur clair
	_flame(h * 0.58, 4.2 * flicker, Color(1.0, 0.96, 0.65, 0.95))


func _flame(h: float, w: float, col: Color) -> void:
	draw_colored_polygon(PackedVector2Array([
		Vector2(0, -h),
		Vector2(w, -h * 0.35),
		Vector2(w * 0.5, h * 0.28),
		Vector2(-w * 0.5, h * 0.28),
		Vector2(-w, -h * 0.35),
	]), col)
