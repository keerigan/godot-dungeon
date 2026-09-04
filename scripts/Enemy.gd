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
var _hit_cd := 0.0                        ## Anti multi-coups (pièges surtout)

var path: PackedVector2Array = PackedVector2Array()  ## Chemin A* (points monde)
var path_i := 0


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
	z_index = 2   # au-dessus du sol/pièges, sous le héros
	var shape := CircleShape2D.new()
	shape.radius = radius
	var cs := CollisionShape2D.new()
	cs.shape = shape
	add_child(cs)


func _physics_process(delta: float) -> void:
	_wobble += delta * 6.0
	if _hit_cd > 0.0:
		_hit_cd -= delta

	# Suit le chemin A* (contourne les murs) ; sinon fonce vers la cible
	var goal := Vector2.ZERO
	var have_goal := false
	if path.size() > 0:
		while path_i < path.size() and global_position.distance_to(path[path_i]) < 12.0:
			path_i += 1
		if path_i < path.size():
			goal = path[path_i]
			have_goal = true
	if not have_goal and target != null and is_instance_valid(target):
		goal = target.global_position
		have_goal = true

	var chase := Vector2.ZERO
	if have_goal:
		var to_goal := goal - global_position
		if to_goal.length() > 1.0:
			chase = to_goal.normalized() * speed
	velocity = chase + _knockback
	_knockback = _knockback.move_toward(Vector2.ZERO, 1400.0 * delta)
	move_and_slide()
	if _flash > 0.0:
		_flash -= delta
	queue_redraw()


func set_path(pts: PackedVector2Array) -> void:
	path = pts
	path_i = 0


## Encaisse un coup. Renvoie true si l'ennemi meurt (false si en cooldown).
func take_hit(from_dir: Vector2) -> bool:
	if _hit_cd > 0.0:
		return false
	_hit_cd = 0.3
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
