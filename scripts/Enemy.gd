class_name Enemy
extends CharacterBody2D

## Ennemi qui poursuit le joueur. Trois variantes (kind) :
##   0 = poursuiveur (rouge, PV 1)
##   1 = rapide (orange, petit, PV 1)
##   2 = costaud (violet, gros, PV 2)

enum Kind { CHASER, FAST, TANK }

var kind: int = Kind.CHASER
var radius := 19.0
var speed := 120.0
var hp := 1
var body_color := Color(0.87, 0.33, 0.31)
var target: Node2D

var _knockback := Vector2.ZERO
var _flash := 0.0
var _wobble := 0.0


func setup(new_kind: int, level: int) -> void:
	kind = new_kind
	match kind:
		Kind.FAST:
			radius = 15.0
			hp = 1
			speed = min(150.0 + level * 14.0, 300.0)
			body_color = Color(0.95, 0.55, 0.22)
		Kind.TANK:
			radius = 26.0
			hp = 2
			speed = min(70.0 + level * 8.0, 150.0)
			body_color = Color(0.66, 0.36, 0.86)
		_:
			radius = 19.0
			hp = 1
			speed = min(95.0 + level * 12.0, 230.0)
			body_color = Color(0.87, 0.33, 0.31)


func _ready() -> void:
	collision_layer = 4
	collision_mask = 1
	var shape := CircleShape2D.new()
	shape.radius = radius
	var cs := CollisionShape2D.new()
	cs.shape = shape
	add_child(cs)


func _physics_process(delta: float) -> void:
	_wobble += delta * 6.0
	var chase := Vector2.ZERO
	if target != null and is_instance_valid(target):
		var to_target := target.global_position - global_position
		if to_target.length() > 1.0:
			chase = to_target.normalized() * speed
	velocity = chase + _knockback
	_knockback = _knockback.move_toward(Vector2.ZERO, 1400.0 * delta)
	move_and_slide()
	if _flash > 0.0:
		_flash -= delta
	queue_redraw()


## Encaisse un coup. Renvoie true si l'ennemi meurt.
func take_hit(from_dir: Vector2) -> bool:
	hp -= 1
	_flash = 0.14
	_knockback = from_dir.normalized() * 420.0
	return hp <= 0


func _draw() -> void:
	var squash := 1.0 + sin(_wobble) * 0.06
	var r := radius
	# Corps
	draw_circle(Vector2.ZERO, r, body_color)
	draw_arc(Vector2.ZERO, r, 0.0, TAU, 28, body_color.darkened(0.4), 3.0)
	# Yeux
	var eye := r * 0.32
	draw_circle(Vector2(-r * 0.32, -r * 0.15 * squash), eye, Color(1, 1, 1))
	draw_circle(Vector2(r * 0.32, -r * 0.15 * squash), eye, Color(1, 1, 1))
	draw_circle(Vector2(-r * 0.32, -r * 0.15 * squash), eye * 0.45, Color(0.1, 0.05, 0.05))
	draw_circle(Vector2(r * 0.32, -r * 0.15 * squash), eye * 0.45, Color(0.1, 0.05, 0.05))
	# Flash blanc quand touché
	if _flash > 0.0:
		draw_circle(Vector2.ZERO, r, Color(1, 1, 1, clampf(_flash / 0.14, 0.0, 0.85)))
