class_name Chest
extends Area2D

## Coffre à ouvrir en marchant dessus. Donne une récompense aléatoire (géré par Game).

signal opened(pos: Vector2)

const RADIUS := 20.0

var _t := 0.0
var _open := false


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
	if body is Player and not _open:
		_open = true
		opened.emit(global_position)
		queue_free()


func _draw() -> void:
	# Lueur dorée pulsante
	var glow := 0.16 + sin(_t * 3.0) * 0.06
	draw_circle(Vector2.ZERO, RADIUS + 6.0, Color(1.0, 0.8, 0.3, glow))

	var wood := Color(0.45, 0.28, 0.15)
	var wood_d := Color(0.32, 0.19, 0.10)
	var gold := Color(0.95, 0.78, 0.28)
	# Corps
	draw_rect(Rect2(-16, -4, 32, 18), wood)
	draw_rect(Rect2(-16, -4, 32, 18), wood_d, false, 2.0)
	# Couvercle bombé
	draw_rect(Rect2(-16, -14, 32, 11), wood.lightened(0.08))
	draw_rect(Rect2(-16, -14, 32, 11), wood_d, false, 2.0)
	# Bandes dorées
	draw_rect(Rect2(-16, -5, 32, 3), gold)
	draw_line(Vector2(-8, -14), Vector2(-8, 14), gold, 2.0)
	draw_line(Vector2(8, -14), Vector2(8, 14), gold, 2.0)
	# Serrure
	draw_rect(Rect2(-4, -6, 8, 8), gold)
	draw_circle(Vector2(0, -2), 1.6, wood_d)
