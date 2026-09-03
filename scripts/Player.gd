class_name Player
extends CharacterBody2D

## Le héros contrôlé par le joueur.
## Se déplace au clavier (ZQSD / WASD / flèches) et au joystick tactile.

signal died
signal health_changed(current: int, maximum: int)
signal coins_changed(count: int)

const SPEED := 260.0
const RADIUS := 22.0

var max_health := 5
var health := 5
var coins := 0
var invuln := 0.0                       ## Temps d'invincibilité restant (secondes)
var joystick_vector := Vector2.ZERO      ## Rempli par le joystick tactile

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
	velocity = dir * SPEED
	move_and_slide()

	if invuln > 0.0:
		invuln -= delta
	# Toujours redessiner : garantit le retour à l'état normal après le
	# clignotement d'invincibilité.
	queue_redraw()

func take_damage(amount: int) -> void:
	if invuln > 0.0:
		return
	health = max(0, health - amount)
	invuln = 1.0
	health_changed.emit(health, max_health)
	queue_redraw()
	if health <= 0:
		died.emit()

func add_coin() -> void:
	coins += 1
	coins_changed.emit(coins)

func reset() -> void:
	health = max_health
	invuln = 0.0
	joystick_vector = Vector2.ZERO
	velocity = Vector2.ZERO
	health_changed.emit(health, max_health)
	queue_redraw()

func _draw() -> void:
	# Clignotement pendant l'invincibilité
	if invuln > 0.0 and int(invuln * 12.0) % 2 == 0:
		return
	draw_circle(Vector2.ZERO, RADIUS, Color(0.95, 0.85, 0.30))
	draw_arc(Vector2.ZERO, RADIUS, 0.0, TAU, 32, Color(0.35, 0.30, 0.10), 3.0)
	# Yeux
	draw_circle(Vector2(-7, -4), 3.5, Color(0.12, 0.10, 0.15))
	draw_circle(Vector2(7, -4), 3.5, Color(0.12, 0.10, 0.15))
	# Sourire
	draw_arc(Vector2(0, 2), 9.0, 0.15 * PI, 0.85 * PI, 12, Color(0.12, 0.10, 0.15), 2.5)
