class_name Enemy
extends CharacterBody2D

## Ennemi qui poursuit le joueur. Trois variantes (kind) :
##   0 = poursuiveur (rouge, PV 1)
##   1 = rapide (orange, petit, PV 1)
##   2 = costaud (violet, gros, PV 2)

enum Kind { CHASER, FAST, TANK, BOSS, GHOST, ZIGZAG, SPLITTER }

var kind: int = Kind.CHASER
var radius := 19.0          ## Rayon visuel
var col_radius := 19.0      ## Rayon de collision (plus petit pour le boss)
var speed := 120.0
var hp := 1
var max_hp := 1
var body_color := Color(0.87, 0.33, 0.31)
var target: Node2D

var _knockback := Vector2.ZERO
var _flash := 0.0
var _wobble := 0.0
var _hit_cd := 0.0                        ## Anti multi-coups (pièges surtout)
var _charge_t := 0.0                       ## Temps de charge restant (boss)
var _charge_cd := 3.0                      ## Délai avant la prochaine charge (boss)
var frozen := false                        ## Gelé (bonus de coffre) : ne bouge plus

var path: PackedVector2Array = PackedVector2Array()  ## Chemin A* (points monde)
var path_i := 0


func setup(new_kind: int, level: int) -> void:
	kind = new_kind
	match kind:
		Kind.FAST:
			radius = 15.0
			hp = 1
			speed = min(140.0 + level * 12.0, 240.0)   # < vitesse du héros
			body_color = Color(0.95, 0.55, 0.22)
		Kind.TANK:
			radius = 26.0
			hp = 2
			speed = min(70.0 + level * 8.0, 150.0)
			body_color = Color(0.66, 0.36, 0.86)
		Kind.BOSS:
			radius = 42.0
			hp = 5 + int(level / 5) * 2      # de plus en plus coriace
			speed = min(140.0 + level * 3.0, 200.0)
			body_color = Color(0.55, 0.16, 0.34)
		Kind.GHOST:
			radius = 18.0
			hp = 1
			speed = min(85.0 + level * 8.0, 185.0)   # traverse les murs
			body_color = Color(0.72, 0.82, 0.98)
		Kind.ZIGZAG:
			radius = 17.0
			hp = 1
			speed = min(110.0 + level * 9.0, 205.0)   # trajectoire sinueuse
			body_color = Color(0.30, 0.82, 0.70)
		Kind.SPLITTER:
			radius = 22.0
			hp = 1
			speed = min(85.0 + level * 8.0, 175.0)    # se divise à la mort
			body_color = Color(0.5, 0.8, 0.32)
		_:
			radius = 19.0
			hp = 1
			speed = min(95.0 + level * 10.0, 215.0)
			body_color = Color(0.87, 0.33, 0.31)
	max_hp = hp
	# Le boss reste visuellement gros mais avec une collision qui tient dans un couloir
	col_radius = 26.0 if kind == Kind.BOSS else radius


func _ready() -> void:
	collision_layer = 4
	collision_mask = 0 if kind == Kind.GHOST else 1   # le fantôme traverse les murs
	z_index = 2   # au-dessus du sol/pièges, sous le héros
	var shape := CircleShape2D.new()
	shape.radius = col_radius
	var cs := CollisionShape2D.new()
	cs.shape = shape
	add_child(cs)


func _physics_process(delta: float) -> void:
	_wobble += delta * 6.0
	if _hit_cd > 0.0:
		_hit_cd -= delta

	# Charge périodique du boss
	var spd := speed
	if kind == Kind.BOSS:
		if _charge_t > 0.0:
			_charge_t -= delta
			spd = speed * 1.8
		else:
			_charge_cd -= delta
			if _charge_cd <= 0.0:
				_charge_t = 0.7
				_charge_cd = randf_range(2.6, 4.2)

	# Le fantôme fonce en ligne droite (traverse les murs) ; les autres suivent A*
	var goal := Vector2.ZERO
	var have_goal := false
	if kind != Kind.GHOST and path.size() > 0:
		while path_i < path.size() and global_position.distance_to(path[path_i]) < 12.0:
			path_i += 1
		if path_i < path.size():
			goal = path[path_i]
			have_goal = true
	if not have_goal and target != null and is_instance_valid(target):
		goal = target.global_position
		have_goal = true

	var chase := Vector2.ZERO
	if have_goal and not frozen:
		var to_goal := goal - global_position
		if to_goal.length() > 1.0:
			chase = to_goal.normalized() * spd
			if kind == Kind.ZIGZAG:
				chase += chase.orthogonal().normalized() * (sin(_wobble * 2.2) * spd * 0.55)
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
	# Ombre douce au sol
	draw_set_transform(Vector2(0, r * 0.82), 0.0, Vector2(1.0, 0.42))
	draw_circle(Vector2.ZERO, r * 0.85, Color(0, 0, 0, 0.30))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# Cornes du boss
	if kind == Kind.BOSS:
		var horn := body_color.darkened(0.35)
		draw_colored_polygon(PackedVector2Array([
			Vector2(-r * 0.7, -r * 0.6), Vector2(-r * 0.35, -r * 0.55),
			Vector2(-r * 0.55, -r * 1.15)]), horn)
		draw_colored_polygon(PackedVector2Array([
			Vector2(r * 0.7, -r * 0.6), Vector2(r * 0.35, -r * 0.55),
			Vector2(r * 0.55, -r * 1.15)]), horn)
	# Corps (le fantôme est translucide)
	var bcol := body_color
	if kind == Kind.GHOST:
		bcol.a = 0.6
	draw_circle(Vector2.ZERO, r, bcol)
	draw_arc(Vector2.ZERO, r, 0.0, TAU, 28, body_color.darkened(0.4), 3.0)
	# Yeux
	var eye := r * 0.32
	draw_circle(Vector2(-r * 0.32, -r * 0.15 * squash), eye, Color(1, 1, 1))
	draw_circle(Vector2(r * 0.32, -r * 0.15 * squash), eye, Color(1, 1, 1))
	draw_circle(Vector2(-r * 0.32, -r * 0.15 * squash), eye * 0.45, Color(0.1, 0.05, 0.05))
	draw_circle(Vector2(r * 0.32, -r * 0.15 * squash), eye * 0.45, Color(0.1, 0.05, 0.05))
	# Givre quand gelé
	if frozen:
		draw_circle(Vector2.ZERO, r, Color(0.6, 0.85, 1.0, 0.4))
		draw_arc(Vector2.ZERO, r, 0.0, TAU, 24, Color(0.8, 0.95, 1.0, 0.8), 2.0)
	# Flash blanc quand touché
	if _flash > 0.0:
		draw_circle(Vector2.ZERO, r, Color(1, 1, 1, clampf(_flash / 0.14, 0.0, 0.85)))

	# Barre de vie du boss
	if kind == Kind.BOSS and max_hp > 0:
		var bw := 64.0
		var by := -r - 16.0
		var frac := clampf(float(hp) / max_hp, 0.0, 1.0)
		draw_rect(Rect2(-bw * 0.5, by, bw, 7), Color(0, 0, 0, 0.65))
		draw_rect(Rect2(-bw * 0.5, by, bw * frac, 7), Color(0.9, 0.3, 0.35))
		draw_rect(Rect2(-bw * 0.5, by, bw, 7), Color(1, 1, 1, 0.55), false, 1.0)
