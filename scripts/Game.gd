extends Node2D

## Boucle de jeu principale.
## Donjon 2D avec éclairage dynamique, particules, écran-titre, portail de
## sortie, bonus, plusieurs types d'ennemis et meilleur score sauvegardé.
## Tout est dessiné / généré par code : aucun asset binaire.

const TILE := 64
const COLS := 13
const ROWS := 21
const MAP_W := COLS * TILE
const MAP_H := ROWS * TILE
const SPAWN_CELL := Vector2i(COLS / 2, ROWS / 2)
const SAVE_PATH := "user://dungeon.cfg"

enum State { TITLE, PLAYING, DEAD }

## Thèmes visuels (100% code). Chaque palette reskin le donjon.
const PALETTES: Array = [
	{
		"name": "Néon",
		"ambient": Color(0.34, 0.32, 0.44),
		"floor_a": Color(0.115, 0.115, 0.15), "floor_b": Color(0.135, 0.135, 0.175),
		"wall_face": Color(0.21, 0.19, 0.27), "wall_top": Color(0.32, 0.29, 0.40),
		"wall_left": Color(0.28, 0.25, 0.35), "wall_bot": Color(0.10, 0.09, 0.13),
		"wall_right": Color(0.12, 0.10, 0.15), "seam": Color(0.09, 0.08, 0.11),
		"crack": Color(0.07, 0.07, 0.10),
		"torch": Color(1.0, 0.72, 0.40), "plight": Color(1.0, 0.92, 0.72),
	},
	{
		"name": "Lave",
		"ambient": Color(0.44, 0.27, 0.22),
		"floor_a": Color(0.15, 0.09, 0.09), "floor_b": Color(0.18, 0.10, 0.09),
		"wall_face": Color(0.28, 0.14, 0.12), "wall_top": Color(0.44, 0.22, 0.16),
		"wall_left": Color(0.36, 0.18, 0.14), "wall_bot": Color(0.12, 0.06, 0.05),
		"wall_right": Color(0.14, 0.07, 0.06), "seam": Color(0.10, 0.05, 0.04),
		"crack": Color(0.75, 0.32, 0.10),
		"torch": Color(1.0, 0.5, 0.2), "plight": Color(1.0, 0.82, 0.5),
	},
	{
		"name": "Glacier",
		"ambient": Color(0.28, 0.34, 0.48),
		"floor_a": Color(0.11, 0.14, 0.19), "floor_b": Color(0.13, 0.16, 0.22),
		"wall_face": Color(0.17, 0.22, 0.32), "wall_top": Color(0.30, 0.40, 0.52),
		"wall_left": Color(0.24, 0.31, 0.42), "wall_bot": Color(0.08, 0.11, 0.16),
		"wall_right": Color(0.10, 0.13, 0.18), "seam": Color(0.07, 0.09, 0.13),
		"crack": Color(0.5, 0.7, 0.92),
		"torch": Color(0.6, 0.85, 1.0), "plight": Color(0.82, 0.92, 1.0),
	},
	{
		"name": "Forêt",
		"ambient": Color(0.28, 0.40, 0.30),
		"floor_a": Color(0.10, 0.14, 0.11), "floor_b": Color(0.12, 0.16, 0.12),
		"wall_face": Color(0.16, 0.24, 0.17), "wall_top": Color(0.28, 0.42, 0.28),
		"wall_left": Color(0.22, 0.33, 0.22), "wall_bot": Color(0.07, 0.11, 0.08),
		"wall_right": Color(0.09, 0.13, 0.09), "seam": Color(0.06, 0.10, 0.07),
		"crack": Color(0.30, 0.50, 0.22),
		"torch": Color(0.7, 1.0, 0.5), "plight": Color(0.85, 1.0, 0.72),
	},
	{
		"name": "Rétro",
		"ambient": Color(0.55, 0.66, 0.36),
		"floor_a": Color(0.18, 0.22, 0.12), "floor_b": Color(0.22, 0.27, 0.14),
		"wall_face": Color(0.30, 0.37, 0.18), "wall_top": Color(0.45, 0.55, 0.28),
		"wall_left": Color(0.38, 0.47, 0.23), "wall_bot": Color(0.14, 0.18, 0.09),
		"wall_right": Color(0.16, 0.20, 0.10), "seam": Color(0.10, 0.13, 0.06),
		"crack": Color(0.25, 0.30, 0.15),
		"torch": Color(0.75, 0.9, 0.4), "plight": Color(0.82, 0.95, 0.5),
	},
]

var walls: Array = []
var wall_bodies: Array[StaticBody2D] = []
var enemies: Array[Enemy] = []
var coins: Array[Coin] = []
var powerups: Array[Powerup] = []
var traps: Array[Trap] = []
var portal: Portal

var player: Player
var camera: Camera2D
var state: int = State.TITLE
var level := 1
var coins_left := 0
var coins_on_level := 0
var best_score := 0
var vibration_enabled := true
var theme_idx := 0

# Éclairage / ambiance
var _light_tex: GradientTexture2D
var _player_light: PointLight2D
var _exit_arrow: ExitArrow
var _ambient: CanvasModulate
# Couleurs du thème courant (dépaquetées depuis PALETTES)
var _c_ambient: Color
var _c_floor_a: Color
var _c_floor_b: Color
var _c_wall_face: Color
var _c_wall_top: Color
var _c_wall_left: Color
var _c_wall_bot: Color
var _c_wall_right: Color
var _c_seam: Color
var _c_crack: Color
var _c_torch: Color
var _c_plight: Color
var _torches: Array[PointLight2D] = []
var _torch_phase: Array = []
var _decor: Array[Node] = []      # particules d'ambiance à libérer entre niveaux
var _time := 0.0
var _shake := 0.0
var _astar: AStarGrid2D
var _path_timer := 0.0

# Interface
var ui_layer: CanvasLayer
var hud_root: Control
var joystick: VirtualJoystick
var level_label: Label
var coins_label: Label
var score_label: Label
var hearts: HeartsBar
var flash_label: Label
var title_root: Control
var title_best: Label
var vib_btn: Button
var theme_btn: Button
var gameover_root: Control
var gameover_score: Label


func _ready() -> void:
	randomize()
	_load_prefs()
	_unpack_theme()
	_light_tex = FX.make_light_texture(256)

	_ambient = CanvasModulate.new()
	_ambient.color = _c_ambient   # obscurité de base du donjon (selon thème)
	add_child(_ambient)

	_build_ui()
	_create_player()
	Sfx.play_music()

	state = State.TITLE
	player.visible = false
	joystick.set_process_input(false)
	build_level()
	title_root.visible = true
	hud_root.visible = false


func _process(delta: float) -> void:
	_time += delta
	_animate_torches()
	_apply_shake(delta)
	if state != State.PLAYING:
		return
	player.joystick_vector = joystick.output

	# Recalcule les chemins des ennemis à intervalle régulier
	_path_timer -= delta
	if _path_timer <= 0.0:
		_path_timer = 0.4
		_update_enemy_paths()

	# Contact ennemi -> dégâts au joueur
	for e in enemies:
		if is_instance_valid(e):
			var contact := Player.RADIUS + e.radius - 4.0
			if player.global_position.distance_to(e.global_position) < contact:
				var hp := player.health
				player.take_damage(1)
				if player.health < hp:
					add_shake(7.0)
					_vibrate(120)
				break

	# Pièges dangereux -> blessent le joueur ET les ennemis
	for t in traps:
		if not (is_instance_valid(t) and t.is_dangerous()):
			continue
		if absf(player.global_position.x - t.global_position.x) < 26.0 \
				and absf(player.global_position.y - t.global_position.y) < 26.0:
			var hp2 := player.health
			player.take_damage(1)
			if player.health < hp2:
				add_shake(6.0)
				_vibrate(120)
		var survivors: Array[Enemy] = []
		for e in enemies:
			if not is_instance_valid(e):
				continue
			if absf(e.global_position.x - t.global_position.x) < 26.0 \
					and absf(e.global_position.y - t.global_position.y) < 26.0:
				var dir := e.global_position - t.global_position
				if dir.length() < 0.01:
					dir = Vector2.UP
				if e.take_hit(dir):
					_kill_enemy(e)
				else:
					survivors.append(e)
			else:
				survivors.append(e)
		enemies = survivors


# ---------------------------------------------------------------------------
# Cycle de jeu
# ---------------------------------------------------------------------------

func start_game() -> void:
	title_root.visible = false
	gameover_root.visible = false
	hud_root.visible = true
	state = State.PLAYING
	joystick.set_process_input(true)
	_exit_arrow.enabled = true
	level = 1
	player.coins = 0
	player.visible = true
	build_level()


func build_level() -> void:
	_clear_level()
	_generate_walls()
	_build_wall_bodies()
	_build_astar()
	_place_torches()
	_place_ambient_dust()

	player.global_position = _cell_to_world(SPAWN_CELL.x, SPAWN_CELL.y)
	player.reset()
	player.visible = (state == State.PLAYING)

	var free_cells := _free_cells()
	free_cells.shuffle()

	# Portail à la case libre la plus éloignée du départ
	_spawn_portal(_farthest_cell(free_cells))

	# Pièges (de plus en plus nombreux, jamais collés au départ)
	var trap_count := 1 + int(level / 2)
	for i in trap_count:
		if free_cells.is_empty():
			break
		var tc: Vector2i = free_cells.pop_back()
		if Vector2(tc).distance_to(Vector2(SPAWN_CELL)) >= 3.0:
			_spawn_trap(tc)

	# Pièces
	coins_on_level = 6 + level
	coins_left = 0
	for i in coins_on_level:
		if free_cells.is_empty():
			break
		_spawn_coin(free_cells.pop_back())
		coins_left += 1
	coins_on_level = coins_left

	# Bonus (0 à 2 selon la chance)
	var bonus_count := (1 if randf() < 0.75 else 0) + (1 if randf() < 0.35 else 0)
	for i in bonus_count:
		if free_cells.is_empty():
			break
		var kind := Powerup.Kind.HEART if randf() < 0.6 else Powerup.Kind.SPEED
		_spawn_powerup(free_cells.pop_back(), kind)

	# Ennemis variés, loin du héros
	var enemy_count := mini(2 + level, 8)
	var placed := 0
	for c in free_cells:
		if placed >= enemy_count:
			break
		if Vector2(c).distance_to(Vector2(SPAWN_CELL)) >= 4.0:
			_spawn_enemy(c)
			placed += 1

	_update_enemy_paths()
	queue_redraw()
	_update_hud()
	if state == State.PLAYING:
		_flash("Niveau %d" % level)


func _open_exit() -> void:
	if portal != null:
		portal.activate()
	_exit_arrow.active = true
	Sfx.play(Sfx.door)
	_flash("Sortie ouverte !")


func _on_portal_entered() -> void:
	if state != State.PLAYING or coins_left > 0:
		return
	Sfx.play(Sfx.level_up)
	_vibrate(60)
	level += 1
	build_level()


func _on_player_died() -> void:
	Sfx.play(Sfx.game_over)
	state = State.DEAD
	add_shake(16.0)
	hud_root.visible = false
	_exit_arrow.enabled = false
	joystick.set_process_input(false)
	joystick.output = Vector2.ZERO
	for e in enemies:
		if is_instance_valid(e):
			e.target = null
	_vibrate(300)
	if player.coins > best_score:
		best_score = player.coins
		_save_prefs()
	gameover_score.text = "Score : %d   ·   Niveau %d\nMeilleur : %d" % [player.coins, level, best_score]
	gameover_root.visible = true


func _on_coin_collected(pos: Vector2) -> void:
	Sfx.play(Sfx.coin)
	player.add_coin()
	coins_left -= 1
	_burst(pos, Color(1.0, 0.85, 0.3), 8, 150.0, 0.4)
	_update_hud()
	if coins_left <= 0:
		_open_exit()


func _on_powerup(kind: int) -> void:
	Sfx.play(Sfx.powerup)
	_vibrate(40)
	if kind == Powerup.Kind.HEART:
		player.heal(1)
		_burst(player.global_position, Color(0.92, 0.3, 0.4), 12, 170.0, 0.5)
	else:
		player.grant_speed(6.0)
		_burst(player.global_position, Color(0.4, 0.9, 1.0), 12, 170.0, 0.5)
	_update_hud()


func _kill_enemy(e: Enemy) -> void:
	_burst(e.global_position, e.body_color, 16, 260.0, 0.5)
	Sfx.play(Sfx.enemy_die)
	player.coins += 2                 # bonus de score
	player.coins_changed.emit(player.coins)
	add_shake(4.0)
	_vibrate(25)
	e.queue_free()


# ---------------------------------------------------------------------------
# Construction du monde
# ---------------------------------------------------------------------------

func _clear_level() -> void:
	for b in wall_bodies:
		if is_instance_valid(b):
			b.queue_free()
	wall_bodies.clear()
	for e in enemies:
		if is_instance_valid(e):
			e.queue_free()
	enemies.clear()
	for c in coins:
		if is_instance_valid(c):
			c.queue_free()
	coins.clear()
	for pw in powerups:
		if is_instance_valid(pw):
			pw.queue_free()
	powerups.clear()
	for t in traps:
		if is_instance_valid(t):
			t.queue_free()
	traps.clear()
	for lt in _torches:
		if is_instance_valid(lt):
			lt.queue_free()
	_torches.clear()
	_torch_phase.clear()
	for d in _decor:
		if is_instance_valid(d):
			d.queue_free()
	_decor.clear()
	if is_instance_valid(portal):
		portal.queue_free()
	portal = null


func _generate_walls() -> void:
	walls.clear()
	for y in ROWS:
		var row: Array = []
		for x in COLS:
			row.append(x == 0 or y == 0 or x == COLS - 1 or y == ROWS - 1)
		walls.append(row)
	var blocks := 8 + level * 3
	for i in blocks:
		var x := randi_range(2, COLS - 3)
		var y := randi_range(2, ROWS - 3)
		if Vector2(x, y).distance_to(Vector2(SPAWN_CELL)) > 2.5:
			walls[y][x] = true


func _build_wall_bodies() -> void:
	for y in ROWS:
		for x in COLS:
			if not walls[y][x]:
				continue
			var body := StaticBody2D.new()
			body.collision_layer = 1
			body.collision_mask = 0
			body.position = _cell_to_world(x, y)
			var shape := RectangleShape2D.new()
			shape.size = Vector2(TILE, TILE)
			var cs := CollisionShape2D.new()
			cs.shape = shape
			body.add_child(cs)
			add_child(body)
			wall_bodies.append(body)


func _place_torches() -> void:
	# Cherche des murs bordant une case de sol pour y poser des torches
	var candidates: Array = []
	for y in range(1, ROWS - 1):
		for x in range(1, COLS - 1):
			if not walls[y][x]:
				continue
			if not walls[y + 1][x]:   # mur avec du sol en dessous
				candidates.append(Vector2i(x, y))
	candidates.shuffle()
	var count: int = min(6, candidates.size())
	for i in count:
		var cell: Vector2i = candidates[i]
		var pos := _cell_to_world(cell.x, cell.y) + Vector2(0, TILE * 0.35)
		var lt := PointLight2D.new()
		lt.texture = _light_tex
		lt.texture_scale = 1.7
		lt.color = _c_torch
		lt.energy = 0.9
		lt.position = pos
		add_child(lt)
		_torches.append(lt)
		_torch_phase.append(randf() * TAU)
		# Braises (teintées comme la torche)
		var em := CPUParticles2D.new()
		em.position = pos
		em.amount = 10
		em.lifetime = 1.3
		em.emitting = true
		em.spread = 22.0
		em.direction = Vector2(0, -1)
		em.gravity = Vector2(0, -24)
		em.initial_velocity_min = 8.0
		em.initial_velocity_max = 22.0
		em.scale_amount_min = 1.5
		em.scale_amount_max = 3.0
		em.color = Color(_c_torch.r, _c_torch.g, _c_torch.b, 0.85)
		add_child(em)
		_decor.append(em)
		# Flamme visible
		var fl := Flame.new()
		fl.position = pos + Vector2(0, -4)
		fl.tint = _c_torch
		add_child(fl)
		_decor.append(fl)


func _place_ambient_dust() -> void:
	var dust := CPUParticles2D.new()
	dust.position = Vector2(MAP_W * 0.5, MAP_H * 0.5)
	dust.amount = 40
	dust.lifetime = 6.5
	dust.emitting = true
	dust.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	dust.emission_rect_extents = Vector2(MAP_W * 0.5, MAP_H * 0.5)
	dust.direction = Vector2(0.3, -1)
	dust.spread = 40.0
	dust.gravity = Vector2(3, -5)
	dust.initial_velocity_min = 3.0
	dust.initial_velocity_max = 11.0
	dust.scale_amount_min = 1.0
	dust.scale_amount_max = 2.2
	dust.color = Color(1.0, 0.92, 0.75, 0.14)
	add_child(dust)
	_decor.append(dust)


func _animate_torches() -> void:
	for i in _torches.size():
		var lt: PointLight2D = _torches[i]
		if is_instance_valid(lt):
			var ph: float = _torch_phase[i]
			lt.energy = 0.82 + sin(_time * 9.0 + ph) * 0.13 + randf() * 0.05


func _free_cells() -> Array:
	var cells: Array = []
	for y in ROWS:
		for x in COLS:
			if not walls[y][x] and Vector2i(x, y) != SPAWN_CELL:
				cells.append(Vector2i(x, y))
	return cells


func _farthest_cell(cells: Array) -> Vector2i:
	var best := SPAWN_CELL
	var best_d := -1.0
	for c in cells:
		var d: float = Vector2(c).distance_to(Vector2(SPAWN_CELL))
		if d > best_d:
			best_d = d
			best = c
	return best


func _spawn_coin(cell: Vector2i) -> void:
	var coin := Coin.new()
	coin.position = _cell_to_world(cell.x, cell.y)
	coin.collected.connect(_on_coin_collected.bind(coin.position))
	add_child(coin)
	coins.append(coin)


func _spawn_powerup(cell: Vector2i, kind: int) -> void:
	var pw := Powerup.new()
	pw.kind = kind
	pw.position = _cell_to_world(cell.x, cell.y)
	pw.collected.connect(_on_powerup)
	add_child(pw)
	powerups.append(pw)


func _spawn_trap(cell: Vector2i) -> void:
	var t := Trap.new()
	t.position = _cell_to_world(cell.x, cell.y)
	add_child(t)
	traps.append(t)


func _spawn_portal(cell: Vector2i) -> void:
	portal = Portal.new()
	portal.position = _cell_to_world(cell.x, cell.y)
	portal.entered.connect(_on_portal_entered)
	add_child(portal)
	_exit_arrow.target = portal
	_exit_arrow.active = false


func _spawn_enemy(cell: Vector2i) -> void:
	var roll := randf()
	var kind := Enemy.Kind.CHASER
	if level >= 2 and roll < 0.3:
		kind = Enemy.Kind.FAST
	elif level >= 3 and roll > 0.8:
		kind = Enemy.Kind.TANK
	var e := Enemy.new()
	e.setup(kind, level)
	e.position = _cell_to_world(cell.x, cell.y)
	e.target = player if state == State.PLAYING else null
	add_child(e)
	enemies.append(e)


func _create_player() -> void:
	player = Player.new()
	player.z_index = 3   # le héros est toujours au premier plan
	player.died.connect(_on_player_died)
	player.health_changed.connect(func(_c, _m): _update_hud())
	player.coins_changed.connect(func(_c): _update_hud())
	add_child(player)

	_player_light = PointLight2D.new()
	_player_light.texture = _light_tex
	_player_light.texture_scale = 3.3
	_player_light.color = _c_plight
	_player_light.energy = 1.15
	player.add_child(_player_light)

	_exit_arrow = ExitArrow.new()
	player.add_child(_exit_arrow)

	camera = Camera2D.new()
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = MAP_W
	camera.limit_bottom = MAP_H
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 8.0
	player.add_child(camera)
	camera.make_current()


func _cell_to_world(x: int, y: int) -> Vector2:
	return Vector2(x * TILE + TILE * 0.5, y * TILE + TILE * 0.5)


func _world_to_cell(pos: Vector2) -> Vector2i:
	return Vector2i(
		clampi(int(pos.x / TILE), 0, COLS - 1),
		clampi(int(pos.y / TILE), 0, ROWS - 1))


func _build_astar() -> void:
	_astar = AStarGrid2D.new()
	_astar.region = Rect2i(0, 0, COLS, ROWS)
	_astar.cell_size = Vector2(TILE, TILE)
	_astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	_astar.update()
	for y in ROWS:
		for x in COLS:
			if walls[y][x]:
				_astar.set_point_solid(Vector2i(x, y), true)


## Recalcule le chemin de chaque ennemi vers le joueur (contourne les murs).
func _update_enemy_paths() -> void:
	if state != State.PLAYING or _astar == null or player == null:
		return
	var pc := _world_to_cell(player.global_position)
	if _astar.is_point_solid(pc):
		return
	for e in enemies:
		if not is_instance_valid(e):
			continue
		var ec := _world_to_cell(e.global_position)
		if _astar.is_point_solid(ec):
			e.set_path(PackedVector2Array())
			continue
		var cells := _astar.get_id_path(ec, pc)
		var pts := PackedVector2Array()
		for i in range(1, cells.size()):   # on saute la case courante
			pts.append(_cell_to_world(cells[i].x, cells[i].y))
		e.set_path(pts)


# ---------------------------------------------------------------------------
# Effets
# ---------------------------------------------------------------------------

func _burst(pos: Vector2, color: Color, count: int, speed: float, lifetime: float) -> void:
	var p := CPUParticles2D.new()
	p.position = pos
	p.emitting = true
	p.one_shot = true
	p.amount = count
	p.lifetime = lifetime
	p.explosiveness = 1.0
	p.spread = 180.0
	p.initial_velocity_min = speed * 0.4
	p.initial_velocity_max = speed
	p.gravity = Vector2.ZERO
	p.scale_amount_min = 2.0
	p.scale_amount_max = 4.5
	p.color = color
	add_child(p)
	get_tree().create_timer(lifetime + 0.3).timeout.connect(p.queue_free)


func add_shake(amount: float) -> void:
	_shake = maxf(_shake, amount)


func _apply_shake(delta: float) -> void:
	if camera == null:
		return
	if _shake > 0.1:
		camera.offset = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * _shake
		_shake = move_toward(_shake, 0.0, 45.0 * delta)
	else:
		camera.offset = Vector2.ZERO


func _camera_punch() -> void:
	if camera == null:
		return
	camera.zoom = Vector2(1.06, 1.06)
	var tw := create_tween()
	tw.tween_property(camera, "zoom", Vector2.ONE, 0.18)


# ---------------------------------------------------------------------------
# Rendu du donjon
# ---------------------------------------------------------------------------

func _draw() -> void:
	if walls.is_empty():
		return
	for y in ROWS:
		for x in COLS:
			if walls[y][x]:
				_draw_wall(x, y)
			else:
				_draw_floor(x, y)


## Petit bruit déterministe et stable par cellule (0..1).
func _hash01(a: int, b: int) -> float:
	var v := sin(a * 12.9898 + b * 78.233) * 43758.5453
	return v - floor(v)


func _draw_floor(x: int, y: int) -> void:
	var r := Rect2(x * TILE, y * TILE, TILE, TILE)
	var n := _hash01(x, y)
	# Damier de pierre légèrement varié
	var base := _c_floor_a if (x + y) % 2 == 0 else _c_floor_b
	base = base.lightened(n * 0.05)
	draw_rect(r, base)
	# Joints (rainures) sombres
	draw_rect(r, _c_seam, false, 1.0)
	# Fissure verticale occasionnelle (rare, en zigzag)
	if _hash01(x * 3 + 1, y * 7 + 2) > 0.93:
		var sx := r.position.x + TILE * (0.35 + n * 0.3)
		var top := r.position.y + TILE * 0.16
		var col := _c_crack
		draw_polyline(PackedVector2Array([
			Vector2(sx, top),
			Vector2(sx + 4.0, top + TILE * 0.28),
			Vector2(sx - 3.0, top + TILE * 0.5),
			Vector2(sx + 2.0, top + TILE * 0.66),
		]), col, 1.5)


func _draw_wall(x: int, y: int) -> void:
	var px := x * TILE
	var py := y * TILE
	var r := Rect2(px, py, TILE, TILE)
	var n := _hash01(x, y)
	# Face du bloc
	draw_rect(r, _c_wall_face.lightened(n * 0.05))
	# Biseau clair (haut + gauche) et ombre (bas + droite) => relief
	draw_rect(Rect2(px, py, TILE, 6), _c_wall_top)
	draw_rect(Rect2(px, py, 6, TILE), _c_wall_left)
	draw_rect(Rect2(px, py + TILE - 6, TILE, 6), _c_wall_bot)
	draw_rect(Rect2(px + TILE - 6, py, 6, TILE), _c_wall_right)
	# Joint de briques au milieu
	draw_line(Vector2(px + 6, py + TILE * 0.5), Vector2(px + TILE - 6, py + TILE * 0.5),
		_c_seam, 2.0)


# ---------------------------------------------------------------------------
# Interface
# ---------------------------------------------------------------------------

func _build_ui() -> void:
	_build_vignette()

	ui_layer = CanvasLayer.new()
	ui_layer.layer = 5
	add_child(ui_layer)

	# Tout le HUD de jeu est regroupé pour être masqué hors des parties
	hud_root = Control.new()
	hud_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	hud_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_root.visible = false
	ui_layer.add_child(hud_root)

	var bar := ColorRect.new()
	bar.color = Color(0, 0, 0, 0.32)
	bar.position = Vector2.ZERO
	bar.size = Vector2(720, 120)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_root.add_child(bar)

	level_label = _make_label("Niveau 1", HORIZONTAL_ALIGNMENT_LEFT)
	coins_label = _make_label("0 / 0 pièces", HORIZONTAL_ALIGNMENT_CENTER)
	score_label = _make_label("Score 0", HORIZONTAL_ALIGNMENT_RIGHT)

	hearts = HeartsBar.new()
	hearts.position = Vector2(34, 84)
	hud_root.add_child(hearts)

	flash_label = Label.new()
	flash_label.add_theme_font_size_override("font_size", 54)
	flash_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	flash_label.size = Vector2(720, 80)
	flash_label.position = Vector2(0, 360)
	flash_label.visible = false
	hud_root.add_child(flash_label)

	joystick = VirtualJoystick.new()
	hud_root.add_child(joystick)

	_build_title_ui()
	_build_gameover_ui()


func _build_vignette() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 2
	add_child(layer)
	var rect := ColorRect.new()
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sh := Shader.new()
	sh.code = """
shader_type canvas_item;
void fragment() {
	float d = distance(SCREEN_UV, vec2(0.5, 0.5));
	float v = smoothstep(0.32, 0.75, d);
	COLOR = vec4(0.0, 0.0, 0.0, v * 0.85);
}
"""
	var mat := ShaderMaterial.new()
	mat.shader = sh
	rect.material = mat
	layer.add_child(rect)


func _make_label(text: String, align: int) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = align
	l.add_theme_font_size_override("font_size", 28)
	l.size = Vector2(680, 44)
	l.position = Vector2(20, 14)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_root.add_child(l)
	return l


func _build_title_ui() -> void:
	title_root = Control.new()
	title_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	title_root.mouse_filter = Control.MOUSE_FILTER_STOP
	title_root.visible = false
	ui_layer.add_child(title_root)

	var dim := ColorRect.new()
	dim.color = Color(0.05, 0.04, 0.09, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	title_root.add_child(dim)

	# Braises flottantes d'ambiance
	var em := CPUParticles2D.new()
	em.position = Vector2(360, 700)
	em.amount = 46
	em.lifetime = 5.0
	em.emitting = true
	em.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	em.emission_rect_extents = Vector2(380, 700)
	em.direction = Vector2(0, -1)
	em.spread = 30.0
	em.gravity = Vector2(0, -12)
	em.initial_velocity_min = 6.0
	em.initial_velocity_max = 20.0
	em.scale_amount_min = 1.5
	em.scale_amount_max = 3.5
	em.color = Color(1.0, 0.75, 0.4, 0.5)
	title_root.add_child(em)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	title_root.add_child(center)

	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 22)
	center.add_child(box)

	var title := Label.new()
	title.text = "DUNGEON RUSH"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 68)
	title.add_theme_color_override("font_color", Color(0.98, 0.82, 0.35))
	box.add_child(title)

	var sub := Label.new()
	sub.text = "Ramasse l'or, survis, trouve la sortie."
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 26)
	sub.add_theme_color_override("font_color", Color(0.85, 0.85, 0.9))
	box.add_child(sub)

	title_best = Label.new()
	title_best.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_best.add_theme_font_size_override("font_size", 24)
	title_best.add_theme_color_override("font_color", Color(0.7, 0.8, 1.0))
	box.add_child(title_best)

	var play := Button.new()
	play.text = "  ▶  JOUER  "
	play.add_theme_font_size_override("font_size", 38)
	play.custom_minimum_size = Vector2(300, 90)
	play.focus_mode = Control.FOCUS_NONE
	play.pressed.connect(start_game)
	box.add_child(play)

	var hint := Label.new()
	hint.text = "Déplace-toi, esquive, ramasse l'or   ·   Clavier : ZQSD / flèches"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 18)
	hint.add_theme_color_override("font_color", Color(0.7, 0.7, 0.75))
	box.add_child(hint)

	theme_btn = Button.new()
	theme_btn.text = _theme_label()
	theme_btn.add_theme_font_size_override("font_size", 24)
	theme_btn.custom_minimum_size = Vector2(300, 58)
	theme_btn.focus_mode = Control.FOCUS_NONE
	theme_btn.pressed.connect(_cycle_theme)
	box.add_child(theme_btn)

	vib_btn = Button.new()
	vib_btn.text = _vib_label()
	vib_btn.add_theme_font_size_override("font_size", 24)
	vib_btn.custom_minimum_size = Vector2(300, 58)
	vib_btn.focus_mode = Control.FOCUS_NONE
	vib_btn.pressed.connect(_toggle_vibration)
	box.add_child(vib_btn)

	_refresh_best_labels()


func _build_gameover_ui() -> void:
	gameover_root = Control.new()
	gameover_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	gameover_root.mouse_filter = Control.MOUSE_FILTER_STOP
	gameover_root.visible = false
	ui_layer.add_child(gameover_root)

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.66)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	gameover_root.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	gameover_root.add_child(center)

	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 28)
	center.add_child(box)

	var title := Label.new()
	title.text = "GAME OVER"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 62)
	title.add_theme_color_override("font_color", Color(0.9, 0.35, 0.32))
	box.add_child(title)

	gameover_score = Label.new()
	gameover_score.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	gameover_score.add_theme_font_size_override("font_size", 30)
	box.add_child(gameover_score)

	var button := Button.new()
	button.text = "  Rejouer  "
	button.add_theme_font_size_override("font_size", 34)
	button.custom_minimum_size = Vector2(260, 78)
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(start_game)
	box.add_child(button)


func _refresh_best_labels() -> void:
	if title_best != null:
		title_best.text = "Meilleur score : %d" % best_score


func _update_hud() -> void:
	level_label.text = "Niveau %d" % level
	coins_label.text = "%d / %d pièces" % [coins_on_level - coins_left, coins_on_level]
	score_label.text = "Score %d" % player.coins
	hearts.set_health(player.health, player.max_health)


func _flash(text: String) -> void:
	flash_label.text = text
	flash_label.modulate = Color(1, 1, 1, 1)
	flash_label.visible = true
	var tween := create_tween()
	tween.tween_interval(0.8)
	tween.tween_property(flash_label, "modulate:a", 0.0, 0.7)
	tween.tween_callback(func(): flash_label.visible = false)


# ---------------------------------------------------------------------------
# Sauvegarde
# ---------------------------------------------------------------------------

func _load_prefs() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) == OK:
		best_score = int(cfg.get_value("score", "best", 0))
		vibration_enabled = bool(cfg.get_value("options", "vibration", true))
		theme_idx = clampi(int(cfg.get_value("options", "theme", 0)), 0, PALETTES.size() - 1)


func _save_prefs() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("score", "best", best_score)
	cfg.set_value("options", "vibration", vibration_enabled)
	cfg.set_value("options", "theme", theme_idx)
	cfg.save(SAVE_PATH)
	_refresh_best_labels()


## Copie la palette courante dans les variables de couleur (rapide pour _draw).
func _unpack_theme() -> void:
	var p: Dictionary = PALETTES[theme_idx]
	_c_ambient = p["ambient"]
	_c_floor_a = p["floor_a"]
	_c_floor_b = p["floor_b"]
	_c_wall_face = p["wall_face"]
	_c_wall_top = p["wall_top"]
	_c_wall_left = p["wall_left"]
	_c_wall_bot = p["wall_bot"]
	_c_wall_right = p["wall_right"]
	_c_seam = p["seam"]
	_c_crack = p["crack"]
	_c_torch = p["torch"]
	_c_plight = p["plight"]


## Applique le thème aux éléments déjà existants (aperçu immédiat).
func _apply_theme() -> void:
	_unpack_theme()
	if _ambient != null:
		_ambient.color = _c_ambient
	if _player_light != null:
		_player_light.color = _c_plight
	for lt in _torches:
		if is_instance_valid(lt):
			lt.color = _c_torch
	queue_redraw()


func _cycle_theme() -> void:
	theme_idx = (theme_idx + 1) % PALETTES.size()
	_apply_theme()
	_save_prefs()
	if theme_btn != null:
		theme_btn.text = _theme_label()


func _theme_label() -> String:
	return "Thème : %s  »" % PALETTES[theme_idx]["name"]


func _vibrate(ms: int) -> void:
	if vibration_enabled:
		Input.vibrate_handheld(ms)


func _toggle_vibration() -> void:
	vibration_enabled = not vibration_enabled
	_save_prefs()
	if vib_btn != null:
		vib_btn.text = _vib_label()
	if vibration_enabled:
		Input.vibrate_handheld(60)   # petit retour tactile de confirmation


func _vib_label() -> String:
	return "Vibrations : %s" % ("ON" if vibration_enabled else "OFF")
