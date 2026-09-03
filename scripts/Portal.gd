class_name Portal
extends Area2D

## Portail de sortie du niveau. Inactif tant que toutes les pièces ne sont pas
## ramassées ; une fois actif, entrer dedans fait passer au niveau suivant.

signal entered

const RADIUS := 30.0

var active := false
var _t := 0.0
var _light: PointLight2D


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2   # détecte le joueur (couche 2)
	monitoring = true
	var shape := CircleShape2D.new()
	shape.radius = RADIUS
	var cs := CollisionShape2D.new()
	cs.shape = shape
	add_child(cs)

	_light = PointLight2D.new()
	_light.texture = FX.make_light_texture(256)
	_light.texture_scale = 1.3
	_light.color = Color(0.45, 0.8, 1.0)
	_light.energy = 0.25
	add_child(_light)

	body_entered.connect(_on_body_entered)


func activate() -> void:
	active = true


func _on_body_entered(body: Node2D) -> void:
	if active and body is Player:
		entered.emit()


func _process(delta: float) -> void:
	_t += delta
	_light.energy = (1.3 if active else 0.22) + sin(_t * 4.0) * 0.12
	queue_redraw()


func _draw() -> void:
	var base := Color(0.5, 0.9, 1.0) if active else Color(0.4, 0.5, 0.65)
	for i in 3:
		var rr := RADIUS - i * 7.0
		var dir := 1.0 if i % 2 == 0 else -1.0
		var start := _t * (1.2 + i) * dir
		draw_arc(Vector2.ZERO, rr, start, start + PI * 1.35, 24, base, 3.0)
	if active:
		var pulse := RADIUS * 0.35 + sin(_t * 6.0) * 4.0
		draw_circle(Vector2.ZERO, pulse, Color(0.8, 0.95, 1.0, 0.5))
