class_name HeartsBar
extends Node2D

## Affiche les points de vie sous forme de cœurs dessinés (HUD).

var current := 5
var maximum := 5

const SPACING := 42.0


func set_health(c: int, m: int) -> void:
	current = c
	maximum = m
	queue_redraw()


func _draw() -> void:
	for i in maximum:
		var o := Vector2(i * SPACING, 0)
		var filled := i < current
		var col := Color(0.92, 0.27, 0.38) if filled else Color(0.28, 0.22, 0.28)
		draw_set_transform(o, 0.0, Vector2.ONE)
		draw_circle(Vector2(-7, -3), 8.0, col)
		draw_circle(Vector2(7, -3), 8.0, col)
		draw_colored_polygon(PackedVector2Array([
			Vector2(-14, -1), Vector2(14, -1), Vector2(0, 15),
		]), col)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
