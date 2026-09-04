class_name Player
extends CharacterBody2D

## Le héros contrôlé par le joueur.
## Se déplace au clavier (ZQSD / WASD / flèches) et au joystick tactile.

signal died
signal health_changed(current: int, maximum: int)
signal coins_changed(count: int)

const SPEED := 265.0
const RADIUS := 22.0

var max_health := 5
var health := 5
var coins := 0
var invuln := 0.0                       ## Temps d'invincibilité restant (secondes)
var joystick_vector := Vector2.ZERO      ## Rempli par le joystick tactile
var facing := Vector2.RIGHT              ## Dernière direction de déplacement
var speed_boost := 0.0                    ## Temps restant du bonus de vitesse
var _bob := 0.0                           ## Animation de balancement
var _blink := 0.0                         ## Temps restant d'un clignement
var _blink_cd := 3.0                      ## Délai avant le prochain clignement

func _ready() -> void:
	collision_layer = 2   # Le joueur est sur la "couche 2"
	collision_mask = 1    # Il n'entre en collision qu'avec les murs (couche 1)
	var shape := CircleShape2D.new()
	shape.radius = RADIUS
	var cs := CollisionShape2D.new()
	cs.shape = shape
	add_child(cs)

func _physics_process(delta: float) -> void:
	var kb := Vector2.ZERO
	if Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT):
		kb.x -= 1.0
	if Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT):
		kb.x += 1.0
	if Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP):
		kb.y -= 1.0
	if Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN):
		kb.y += 1.0

	var dir := joystick_vector + kb
	if dir.length() > 1.0:
		dir = dir.normalized()
	if dir.length() > 0.1:
		facing = dir.normalized()
		_bob += delta * 12.0
	var spd := SPEED * (1.6 if speed_boost > 0.0 else 1.0)
	velocity = dir * spd
	move_and_slide()

	if invuln > 0.0:
		invuln -= delta
	if speed_boost > 0.0:
		speed_boost -= delta
	# Clignement d'yeux périodique
	_blink_cd -= delta
	if _blink_cd <= 0.0:
		_blink = 0.12
		_blink_cd = randf_range(2.5, 4.8)
	if _blink > 0.0:
		_blink -= delta
	# Toujours redessiner : garantit le retour à l'état normal après le
	# clignotement d'invincibilité.
	queue_redraw()

func take_damage(amount: int) -> void:
	if invuln > 0.0:
		return
	health = max(0, health - amount)
	invuln = 1.0
	Sfx.play(Sfx.hurt)
	health_changed.emit(health, max_health)
	queue_redraw()
	if health <= 0:
		died.emit()

func add_coin() -> void:
	coins += 1
	coins_changed.emit(coins)

func heal(amount: int) -> void:
	health = min(max_health, health + amount)
	health_changed.emit(health, max_health)

func grant_speed(duration: float) -> void:
	speed_boost = maxf(speed_boost, duration)

func reset() -> void:
	health = max_health
	invuln = 0.0
	speed_boost = 0.0
	joystick_vector = Vector2.ZERO
	velocity = Vector2.ZERO
	health_changed.emit(health, max_health)
	queue_redraw()

func _draw() -> void:
	# Ombre douce au sol
	draw_set_transform(Vector2(0, RADIUS * 0.85), 0.0, Vector2(1.0, 0.42))
	draw_circle(Vector2.ZERO, RADIUS * 0.85, Color(0, 0, 0, 0.30))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	# Aura de vitesse
	if speed_boost > 0.0:
		draw_arc(Vector2.ZERO, RADIUS + 6.0, 0.0, TAU, 32, Color(0.4, 0.9, 1.0, 0.7), 3.0)

	# Clignotement pendant l'invincibilité
	if invuln > 0.0 and int(invuln * 12.0) % 2 == 0:
		return

	var c := Vector2(0, sin(_bob) * 2.0)   # léger balancement
	draw_circle(c, RADIUS, Color(0.95, 0.85, 0.30))
	draw_arc(c, RADIUS, 0.0, TAU, 32, Color(0.35, 0.30, 0.10), 3.0)
	# Reflet doux
	draw_circle(c + Vector2(-6, -8), 5.0, Color(1.0, 0.96, 0.7, 0.5))
	# Yeux (fermés pendant le clignement)
	var eye_col := Color(0.12, 0.10, 0.15)
	if _blink > 0.0:
		draw_line(c + Vector2(-11, -4), c + Vector2(-3, -4), eye_col, 2.5)
		draw_line(c + Vector2(3, -4), c + Vector2(11, -4), eye_col, 2.5)
	else:
		draw_circle(c + Vector2(-7, -4), 3.5, eye_col)
		draw_circle(c + Vector2(7, -4), 3.5, eye_col)
	# Sourire
	draw_arc(c + Vector2(0, 2), 9.0, 0.15 * PI, 0.85 * PI, 12, eye_col, 2.5)
