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
var magnet := 0.0                         ## Temps restant de l'aimant à pièces
var shield := 0.0                         ## Temps restant du bouclier (invincible)
var _bob := 0.0                           ## Animation de balancement
var _blink := 0.0                         ## Temps restant d'un clignement
var _blink_cd := 3.0                      ## Délai avant le prochain clignement
var body_color := Color(0.95, 0.85, 0.30) ## Couleur du héros (skin)
var rim_color := Color(0.35, 0.30, 0.10)  ## Contour du héros (skin)
var trail_color := Color(1.0, 0.8, 0.3)   ## Couleur de la traînée (skin)
var shape := "orbe"                        ## Forme du personnage (skin)
var speed_mult := 1.0                       ## Multiplicateur de vitesse (bonus skin)
var invuln_time := 1.0                       ## Durée d'invincibilité après un coup (bonus skin)
var phase := false                           ## Traverse les murs (bonus skin)

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
	var spd := SPEED * speed_mult * (1.6 if speed_boost > 0.0 else 1.0)
	velocity = dir * spd
	move_and_slide()

	if invuln > 0.0:
		invuln -= delta
	if speed_boost > 0.0:
		speed_boost -= delta
	if magnet > 0.0:
		magnet -= delta
	if shield > 0.0:
		shield -= delta
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
	if shield > 0.0 or invuln > 0.0:
		return
	health = max(0, health - amount)
	invuln = invuln_time
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

func grant_magnet(duration: float) -> void:
	magnet = maxf(magnet, duration)

func grant_shield(duration: float) -> void:
	shield = maxf(shield, duration)

func reset() -> void:
	health = max_health
	invuln = 0.0
	speed_boost = 0.0
	magnet = 0.0
	shield = 0.0
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
	# Aura d'aimant (or)
	if magnet > 0.0:
		draw_arc(Vector2.ZERO, RADIUS + 11.0, 0.0, TAU, 22, Color(1.0, 0.9, 0.4, 0.5), 2.0)
	# Bouclier (bleu clair)
	if shield > 0.0:
		draw_circle(Vector2.ZERO, RADIUS + 8.0, Color(0.5, 0.8, 1.0, 0.18))
		draw_arc(Vector2.ZERO, RADIUS + 8.0, 0.0, TAU, 36, Color(0.6, 0.85, 1.0, 0.85), 3.0)

	# Clignotement pendant l'invincibilité
	if invuln > 0.0 and int(invuln * 12.0) % 2 == 0:
		return

	var c := Vector2(0, sin(_bob) * 2.0)   # léger balancement
	match shape:
		"fantome": _draw_ghost(c)
		"robot": _draw_robot(c)
		"slime": _draw_slime(c)
		"chat": _draw_cat(c)
		"chevalier": _draw_knight(c)
		"dragon": _draw_dragon(c)
		"crane": _draw_skull(c)
		"ninja": _draw_ninja(c)
		"prisme": _draw_gem(c)
		_: _draw_orbe(c)


## Yeux + sourire partagés par les formes rondes.
func _face(c: Vector2) -> void:
	var eye_col := Color(0.12, 0.10, 0.15)
	if _blink > 0.0:
		draw_line(c + Vector2(-11, -4), c + Vector2(-3, -4), eye_col, 2.5)
		draw_line(c + Vector2(3, -4), c + Vector2(11, -4), eye_col, 2.5)
	else:
		draw_circle(c + Vector2(-7, -4), 3.5, eye_col)
		draw_circle(c + Vector2(7, -4), 3.5, eye_col)
	draw_arc(c + Vector2(0, 2), 9.0, 0.15 * PI, 0.85 * PI, 12, eye_col, 2.5)


func _draw_orbe(c: Vector2) -> void:
	draw_circle(c, RADIUS, body_color)
	draw_arc(c, RADIUS, 0.0, TAU, 32, rim_color, 3.0)
	draw_circle(c + Vector2(-6, -8), 5.0, body_color.lightened(0.5))
	_face(c)


func _draw_ghost(c: Vector2) -> void:
	var pts := PackedVector2Array()
	var seg := 16
	for i in seg + 1:                       # dôme supérieur (gauche -> droite)
		var a := PI + PI * float(i) / seg
		pts.append(c + Vector2(cos(a), sin(a)) * RADIUS)
	var by := RADIUS * 0.72
	var wsteps := 18
	for i in wsteps + 1:                     # bas ondulé (droite -> gauche)
		var t := float(i) / wsteps
		var x := lerpf(RADIUS, -RADIUS, t)
		var y := by + sin(t * PI * 3.0) * (RADIUS * 0.18)
		pts.append(c + Vector2(x, y))
	draw_colored_polygon(pts, body_color)
	draw_polyline(pts, rim_color, 2.0)
	draw_circle(c + Vector2(-7, -3), 3.8, Color(0.1, 0.1, 0.14))
	draw_circle(c + Vector2(7, -3), 3.8, Color(0.1, 0.1, 0.14))
	draw_circle(c + Vector2(-8, -5), 1.4, Color(1, 1, 1, 0.8))
	draw_circle(c + Vector2(6, -5), 1.4, Color(1, 1, 1, 0.8))


func _draw_robot(c: Vector2) -> void:
	var w := RADIUS * 1.5
	var h := RADIUS * 1.5
	var rect := Rect2(c + Vector2(-w * 0.5, -h * 0.5), Vector2(w, h))
	draw_line(c + Vector2(0, -h * 0.5), c + Vector2(0, -h * 0.5 - 8.0), rim_color, 2.0)
	draw_circle(c + Vector2(0, -h * 0.5 - 9.0), 3.0, body_color.lightened(0.4))
	draw_rect(rect, body_color)
	draw_rect(rect, rim_color, false, 2.5)
	var visor := Rect2(c + Vector2(-w * 0.38, -6.0), Vector2(w * 0.76, 10.0))
	draw_rect(visor, Color(0.08, 0.09, 0.13))
	draw_circle(c + Vector2(-6, -1), 2.6, body_color.lightened(0.6))
	draw_circle(c + Vector2(6, -1), 2.6, body_color.lightened(0.6))
	draw_line(c + Vector2(-6, 9), c + Vector2(6, 9), rim_color, 2.0)


func _draw_slime(c: Vector2) -> void:
	var pts := PackedVector2Array()
	var steps := 22
	for i in steps + 1:                      # dôme supérieur écrasé
		var t := float(i) / steps
		var ang := PI * (1.0 - t)
		pts.append(c + Vector2(cos(ang) * RADIUS, -absf(sin(ang)) * RADIUS * 0.95))
	var by := RADIUS * 0.55
	pts.append(c + Vector2(RADIUS * 0.9, by))
	pts.append(c + Vector2(-RADIUS * 0.9, by))
	draw_colored_polygon(pts, body_color)
	draw_polyline(pts, rim_color, 2.0)
	draw_circle(c + Vector2(-6, -8), 4.0, body_color.lightened(0.5))
	_face(c)


func _draw_cat(c: Vector2) -> void:
	var earL := PackedVector2Array([
		c + Vector2(-RADIUS * 0.75, -RADIUS * 0.5),
		c + Vector2(-RADIUS * 0.2, -RADIUS * 0.98),
		c + Vector2(-RADIUS * 0.1, -RADIUS * 0.35)])
	var earR := PackedVector2Array([
		c + Vector2(RADIUS * 0.75, -RADIUS * 0.5),
		c + Vector2(RADIUS * 0.2, -RADIUS * 0.98),
		c + Vector2(RADIUS * 0.1, -RADIUS * 0.35)])
	draw_colored_polygon(earL, body_color)
	draw_colored_polygon(earR, body_color)
	draw_circle(c, RADIUS, body_color)
	draw_arc(c, RADIUS, 0.0, TAU, 32, rim_color, 3.0)
	draw_polyline(earL, rim_color, 2.0)
	draw_polyline(earR, rim_color, 2.0)
	var eye_col := Color(0.12, 0.10, 0.15)
	draw_circle(c + Vector2(-7, -2), 3.2, eye_col)
	draw_circle(c + Vector2(7, -2), 3.2, eye_col)
	draw_circle(c + Vector2(0, 3), 2.0, rim_color)
	draw_line(c + Vector2(-4, 3), c + Vector2(-14, 1), rim_color, 1.2)
	draw_line(c + Vector2(-4, 5), c + Vector2(-14, 6), rim_color, 1.2)
	draw_line(c + Vector2(4, 3), c + Vector2(14, 1), rim_color, 1.2)
	draw_line(c + Vector2(4, 5), c + Vector2(14, 6), rim_color, 1.2)


func _draw_knight(c: Vector2) -> void:
	draw_line(c + Vector2(0, -RADIUS), c + Vector2(0, -RADIUS - 9.0), rim_color, 3.0)
	draw_circle(c + Vector2(0, -RADIUS - 10.0), 3.0, body_color.lightened(0.3))
	draw_circle(c, RADIUS, body_color)
	draw_arc(c, RADIUS, 0.0, TAU, 32, rim_color, 3.0)
	var band := Rect2(c + Vector2(-RADIUS * 0.85, -4.0), Vector2(RADIUS * 1.7, 11.0))
	draw_rect(band, Color(0.09, 0.09, 0.13))
	draw_line(c + Vector2(-6, -3), c + Vector2(-6, 4), body_color.lightened(0.6), 2.5)
	draw_line(c + Vector2(6, -3), c + Vector2(6, 4), body_color.lightened(0.6), 2.5)
	draw_line(c + Vector2(0, -RADIUS), c + Vector2(0, -5), rim_color, 2.0)


func _draw_dragon(c: Vector2) -> void:
	# Cornes
	var horn_col := body_color.lightened(0.35)
	var hornL := PackedVector2Array([
		c + Vector2(-RADIUS * 0.55, -RADIUS * 0.6),
		c + Vector2(-RADIUS * 0.95, -RADIUS * 1.3),
		c + Vector2(-RADIUS * 0.2, -RADIUS * 0.85)])
	var hornR := PackedVector2Array([
		c + Vector2(RADIUS * 0.55, -RADIUS * 0.6),
		c + Vector2(RADIUS * 0.95, -RADIUS * 1.3),
		c + Vector2(RADIUS * 0.2, -RADIUS * 0.85)])
	draw_colored_polygon(hornL, horn_col)
	draw_colored_polygon(hornR, horn_col)
	draw_circle(c, RADIUS, body_color)
	draw_arc(c, RADIUS, 0.0, TAU, 32, rim_color, 3.0)
	# Sourcils fâchés + yeux
	var eye_col := Color(0.12, 0.05, 0.03)
	draw_line(c + Vector2(-12, -8), c + Vector2(-3, -4), eye_col, 2.5)
	draw_line(c + Vector2(12, -8), c + Vector2(3, -4), eye_col, 2.5)
	draw_circle(c + Vector2(-7, -2), 3.0, Color(1, 0.9, 0.4))
	draw_circle(c + Vector2(7, -2), 3.0, Color(1, 0.9, 0.4))
	draw_circle(c + Vector2(-7, -2), 1.3, eye_col)
	draw_circle(c + Vector2(7, -2), 1.3, eye_col)
	# Naseaux
	draw_circle(c + Vector2(-4, 7), 1.6, rim_color)
	draw_circle(c + Vector2(4, 7), 1.6, rim_color)
	# Crocs
	draw_colored_polygon(PackedVector2Array([
		c + Vector2(-6, 11), c + Vector2(-3, 11), c + Vector2(-4.5, 16)]), Color(1, 1, 0.95))
	draw_colored_polygon(PackedVector2Array([
		c + Vector2(6, 11), c + Vector2(3, 11), c + Vector2(4.5, 16)]), Color(1, 1, 0.95))


func _draw_skull(c: Vector2) -> void:
	draw_circle(c, RADIUS, body_color)
	draw_arc(c, RADIUS, 0.0, TAU, 32, rim_color, 3.0)
	var dark := Color(0.1, 0.1, 0.14)
	# Orbites
	draw_circle(c + Vector2(-6, -3), 4.4, dark)
	draw_circle(c + Vector2(6, -3), 4.4, dark)
	# Nez
	draw_colored_polygon(PackedVector2Array([
		c + Vector2(0, 2), c + Vector2(-2.6, 8), c + Vector2(2.6, 8)]), dark)
	# Dents
	var y := RADIUS * 0.6
	draw_line(c + Vector2(-8, y - 4), c + Vector2(8, y - 4), rim_color, 1.5)
	for tx in [-6, -2, 2, 6]:
		draw_line(c + Vector2(tx, y - 4), c + Vector2(tx, y + 2), rim_color, 1.5)


func _draw_ninja(c: Vector2) -> void:
	draw_circle(c, RADIUS, body_color)   # capuche sombre
	draw_arc(c, RADIUS, 0.0, TAU, 32, rim_color, 3.0)
	# Bandeau (bande de peau visible sur les yeux)
	var strip := Rect2(c + Vector2(-RADIUS * 0.92, -6.0), Vector2(RADIUS * 1.84, 11.0))
	draw_rect(strip, Color(0.93, 0.82, 0.68))
	# Yeux
	draw_circle(c + Vector2(-6, -1), 2.4, Color(0.1, 0.1, 0.14))
	draw_circle(c + Vector2(6, -1), 2.4, Color(0.1, 0.1, 0.14))
	# Nœud + rubans du bandeau (à droite)
	draw_line(c + Vector2(RADIUS * 0.8, -1), c + Vector2(RADIUS * 1.35, -6), rim_color, 3.0)
	draw_line(c + Vector2(RADIUS * 0.8, 1), c + Vector2(RADIUS * 1.35, 6), rim_color, 3.0)


func _draw_gem(c: Vector2) -> void:
	var pts := PackedVector2Array([
		c + Vector2(0, -RADIUS),
		c + Vector2(RADIUS * 0.82, -RADIUS * 0.15),
		c + Vector2(0, RADIUS),
		c + Vector2(-RADIUS * 0.82, -RADIUS * 0.15)])
	draw_colored_polygon(pts, body_color)
	# Contour fermé
	var outline := pts.duplicate()
	outline.append(pts[0])
	draw_polyline(outline, rim_color, 2.0)
	# Facettes
	draw_line(c + Vector2(-RADIUS * 0.82, -RADIUS * 0.15), c + Vector2(RADIUS * 0.82, -RADIUS * 0.15),
		body_color.lightened(0.4), 1.5)
	draw_line(c + Vector2(0, -RADIUS), c + Vector2(0, RADIUS), body_color.lightened(0.25), 1.2)
	draw_circle(c + Vector2(-5, -6), 2.4, Color(1, 1, 1, 0.8))
