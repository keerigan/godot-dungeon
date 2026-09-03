class_name Powerup
extends Area2D

## Bonus à ramasser : cœur (soin) ou éclair (vitesse temporaire).

signal collected(kind: int)

enum Kind { HEART, SPEED }

const RADIUS := 16.0

var kind: int = Kind.HEART
var _t := 0.0


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2   # détecte le joueur
	monitoring = true
	var shape := CircleShape2D.new()
	shape.radius = RADIUS
	var cs := CollisionShape2D.new()
	cs.shape = shape
	add_child(cs)
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		collected.emit(kind)
		queue_free()


func _draw() -> void:
	var bob := sin(_t * 3.0) * 3.0
	draw_set_transform(Vector2(0, bob), 0.0, Vector2.ONE)
	# Halo
	draw_circle(Vector2.ZERO, RADIUS + 3.0,
		Color(0.9, 0.3, 0.4, 0.18) if kind == Kind.HEART else Color(0.4, 0.9, 1.0, 0.18))
	if kind == Kind.HEART:
		var col := Color(0.92, 0.27, 0.38)
		draw_circle(Vector2(-6, -3), 7.0, col)
		draw_circle(Vector2(6, -3), 7.0, col)
		draw_colored_polygon(PackedVector2Array([
			Vector2(-12, -1), Vector2(12, -1), Vector2(0, 13),
		]), col)
	else:
		var col := Color(0.45, 0.9, 1.0)
		draw_colored_polygon(PackedVector2Array([
			Vector2(3, -13), Vector2(-7, 2), Vector2(-1, 2),
			Vector2(-4, 13), Vector2(8, -4), Vector2(1, -4),
		]), col)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
