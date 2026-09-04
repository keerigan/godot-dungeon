class_name ItemPickup
extends Area2D

## Objet à usage unique posé au sol. Ramassé au contact (si l'inventaire est
## libre). Le type est une chaîne : "bomb", "freeze", "potion", "blink".

signal picked(kind: String)

const RADIUS := 16.0

var kind: String = "bomb"
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
		picked.emit(kind)
		queue_free()


func _draw() -> void:
	var bob := sin(_t * 3.0) * 3.0
	draw_set_transform(Vector2(0, bob), 0.0, Vector2.ONE)
	# Halo
	draw_circle(Vector2.ZERO, RADIUS + 4.0, Color(1, 1, 1, 0.12))
	match kind:
		"bomb":
			draw_circle(Vector2.ZERO, 12.0, Color(0.12, 0.12, 0.15))
			draw_circle(Vector2.ZERO, 12.0, Color(0.4, 0.4, 0.45), false, 2.0)
			draw_line(Vector2(6, -9), Vector2(11, -15), Color(0.5, 0.35, 0.2), 2.0)
			draw_circle(Vector2(11, -15), 2.5, Color(1.0, 0.7, 0.2))
		"freeze":
			var c := Color(0.6, 0.9, 1.0)
			for i in 3:
				var a := i * PI / 3.0
				var v := Vector2(cos(a), sin(a)) * 12.0
				draw_line(-v, v, c, 2.5)
		"potion":
			draw_rect(Rect2(-5, -12, 10, 6), Color(0.7, 0.8, 0.85))          # goulot
			draw_colored_polygon(PackedVector2Array([
				Vector2(-5, -6), Vector2(5, -6), Vector2(9, 12), Vector2(-9, 12)]),
				Color(0.85, 0.85, 0.9, 0.5))                                 # flacon
			draw_colored_polygon(PackedVector2Array([
				Vector2(-7, 3), Vector2(7, 3), Vector2(8, 11), Vector2(-8, 11)]),
				Color(0.9, 0.25, 0.35))                                      # liquide
		"blink":
			var c := Color(0.5, 0.9, 1.0)
			draw_colored_polygon(PackedVector2Array([
				Vector2(-2, -12), Vector2(-10, 2), Vector2(-4, 2),
				Vector2(-6, 12), Vector2(8, -4), Vector2(0, -4)]), c)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
