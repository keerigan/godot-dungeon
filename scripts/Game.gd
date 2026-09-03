extends Node2D

## Boucle de jeu principale : génère le donjon, place le héros, les pièces
## et les ennemis, gère les niveaux, les dégâts et l'écran de fin.
## Tout le rendu est fait par code (_draw) : aucun asset image nécessaire.

const TILE := 64
const COLS := 13
const ROWS := 21
const MAP_W := COLS * TILE
const MAP_H := ROWS * TILE

enum State { PLAYING, DEAD }

var walls: Array = []                 ## Grille de booléens [ROWS][COLS] : true = mur
var wall_bodies: Array[StaticBody2D] = []
var enemies: Array[Enemy] = []
var coins: Array[Coin] = []

var player: Player
var camera: Camera2D
var state: int = State.PLAYING
var level := 1
var coins_left := 0
var coins_on_level := 0

# --- Interface ---
var ui_layer: CanvasLayer
var joystick: VirtualJoystick
var level_label: Label
var coins_label: Label
var health_label: Label
var flash_label: Label
var gameover_root: Control
var score_label: Label

const SPAWN_CELL := Vector2i(COLS / 2, ROWS / 2)


func _ready() -> void:
	randomize()
	_build_ui()
	_create_player()
	start_new_game()


func _process(_delta: float) -> void:
	if state != State.PLAYING:
		return
	# Transmet la direction du joystick au joueur
	player.joystick_vector = joystick.output
	# Contact avec un ennemi -> dégâts
	var hit_dist := Player.RADIUS + Enemy.RADIUS - 4.0
	for e in enemies:
		if is_instance_valid(e) and player.global_position.distance_to(e.global_position) < hit_dist:
			player.take_damage(1)
			break


# ---------------------------------------------------------------------------
# Cycle de jeu
# ---------------------------------------------------------------------------

func start_new_game() -> void:
	level = 1
	player.coins = 0
	player.reset()
	state = State.PLAYING
	gameover_root.visible = false
	joystick.set_process_input(true)
	build_level()


func build_level() -> void:
	_clear_level()
	_generate_walls()
	_build_wall_bodies()

	# Place le héros au centre et le soigne complètement
	player.global_position = _cell_to_world(SPAWN_CELL.x, SPAWN_CELL.y)
	player.reset()

	var free_cells := _free_cells()
	free_cells.shuffle()

	# Pièces à ramasser
	coins_on_level = 6 + level
	coins_left = 0
	for i in coins_on_level:
		if free_cells.is_empty():
			break
		var c: Vector2i = free_cells.pop_back()
		_spawn_coin(c)
		coins_left += 1
	coins_on_level = coins_left

	# Ennemis, placés loin du héros
	var enemy_count := 2 + level
	var placed := 0
	for c in free_cells:
		if placed >= enemy_count:
			break
		if Vector2(c).distance_to(Vector2(SPAWN_CELL)) >= 4.0:
			_spawn_enemy(c)
			placed += 1

	queue_redraw()
	_update_hud()
	_flash("Niveau %d" % level)


func _on_level_cleared() -> void:
	Sfx.play(Sfx.level_up)
	level += 1
	build_level()


func _on_player_died() -> void:
	Sfx.play(Sfx.game_over)
	state = State.DEAD
	joystick.set_process_input(false)
	joystick.output = Vector2.ZERO
	joystick.queue_redraw()
	for e in enemies:
		if is_instance_valid(e):
			e.target = null
	score_label.text = "Score : %d pièces\nNiveau atteint : %d" % [player.coins, level]
	gameover_root.visible = true


func _on_coin_collected() -> void:
	Sfx.play(Sfx.coin)
	player.add_coin()
	coins_left -= 1
	_update_hud()
	if coins_left <= 0:
		_on_level_cleared()


func _on_player_attacked() -> void:
	if state != State.PLAYING:
		return
	Sfx.play(Sfx.attack)
	var reach := Player.ATTACK_RADIUS + Enemy.RADIUS
	var survivors: Array[Enemy] = []
	var killed := 0
	for e in enemies:
		if not is_instance_valid(e):
			continue
		if player.global_position.distance_to(e.global_position) <= reach:
			e.queue_free()
			killed += 1
		else:
			survivors.append(e)
	enemies = survivors
	if killed > 0:
		Sfx.play(Sfx.enemy_die)
		player.coins += killed          # bonus de score
		player.coins_changed.emit(player.coins)


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


func _generate_walls() -> void:
	walls.clear()
	for y in ROWS:
		var row: Array = []
		for x in COLS:
			var border := x == 0 or y == 0 or x == COLS - 1 or y == ROWS - 1
			row.append(border)
		walls.append(row)

	# Blocs de murs internes aléatoires (on épargne la zone de départ)
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


func _free_cells() -> Array:
	var cells: Array = []
	for y in ROWS:
		for x in COLS:
			if not walls[y][x] and Vector2i(x, y) != SPAWN_CELL:
				cells.append(Vector2i(x, y))
	return cells


func _spawn_coin(cell: Vector2i) -> void:
	var coin := Coin.new()
	coin.position = _cell_to_world(cell.x, cell.y)
	coin.collected.connect(_on_coin_collected)
	add_child(coin)
	coins.append(coin)


func _spawn_enemy(cell: Vector2i) -> void:
	var e := Enemy.new()
	e.position = _cell_to_world(cell.x, cell.y)
	e.speed = min(90.0 + level * 12.0, 220.0)
	e.target = player
	add_child(e)
	enemies.append(e)


func _create_player() -> void:
	player = Player.new()
	player.died.connect(_on_player_died)
	player.attacked.connect(_on_player_attacked)
	player.health_changed.connect(func(_c, _m): _update_hud())
	player.coins_changed.connect(func(_c): _update_hud())
	add_child(player)

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


# ---------------------------------------------------------------------------
# Rendu du donjon
# ---------------------------------------------------------------------------

func _draw() -> void:
	if walls.is_empty():
		return
	for y in ROWS:
		for x in COLS:
			var r := Rect2(x * TILE, y * TILE, TILE, TILE)
			if walls[y][x]:
				draw_rect(r, Color(0.17, 0.15, 0.22))
				draw_rect(r.grow(-2.0), Color(0.27, 0.24, 0.34), false, 2.0)
			else:
				var dark := (x + y) % 2 == 0
				draw_rect(r, Color(0.11, 0.11, 0.14) if dark else Color(0.13, 0.13, 0.17))


# ---------------------------------------------------------------------------
# Interface
# ---------------------------------------------------------------------------

func _build_ui() -> void:
	ui_layer = CanvasLayer.new()
	add_child(ui_layer)

	# Bandeau supérieur
	var bar := ColorRect.new()
	bar.color = Color(0, 0, 0, 0.35)
	bar.position = Vector2.ZERO
	bar.size = Vector2(720, 66)
	ui_layer.add_child(bar)

	level_label = _make_label("Niveau 1", HORIZONTAL_ALIGNMENT_LEFT)
	coins_label = _make_label("Pièces 0/0", HORIZONTAL_ALIGNMENT_CENTER)
	health_label = _make_label("Vie 5/5", HORIZONTAL_ALIGNMENT_RIGHT)

	# Message central temporaire (ex. "Niveau 2")
	flash_label = Label.new()
	flash_label.add_theme_font_size_override("font_size", 52)
	flash_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	flash_label.size = Vector2(720, 80)
	flash_label.position = Vector2(0, 360)
	flash_label.visible = false
	ui_layer.add_child(flash_label)

	# Joystick tactile (au-dessus du reste sauf l'écran de fin)
	joystick = VirtualJoystick.new()
	ui_layer.add_child(joystick)

	# Bouton d'attaque (en bas à droite, hors de la zone du joystick)
	var attack_btn := Button.new()
	attack_btn.text = "ATK"
	attack_btn.add_theme_font_size_override("font_size", 40)
	attack_btn.size = Vector2(150, 150)
	attack_btn.position = Vector2(540, 1070)
	attack_btn.focus_mode = Control.FOCUS_NONE
	attack_btn.modulate = Color(1, 1, 1, 0.88)
	attack_btn.pressed.connect(_on_attack_button)
	ui_layer.add_child(attack_btn)

	_build_gameover_ui()


func _on_attack_button() -> void:
	if state == State.PLAYING:
		player.try_attack()


func _make_label(text: String, align: int) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = align
	l.add_theme_font_size_override("font_size", 28)
	l.size = Vector2(680, 44)
	l.position = Vector2(20, 12)
	ui_layer.add_child(l)
	return l


func _build_gameover_ui() -> void:
	gameover_root = Control.new()
	gameover_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	gameover_root.mouse_filter = Control.MOUSE_FILTER_STOP
	gameover_root.visible = false
	ui_layer.add_child(gameover_root)

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.65)
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
	title.add_theme_font_size_override("font_size", 60)
	title.add_theme_color_override("font_color", Color(0.9, 0.35, 0.32))
	box.add_child(title)

	score_label = Label.new()
	score_label.text = ""
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_label.add_theme_font_size_override("font_size", 30)
	box.add_child(score_label)

	var button := Button.new()
	button.text = "  Rejouer  "
	button.add_theme_font_size_override("font_size", 34)
	button.custom_minimum_size = Vector2(240, 72)
	button.pressed.connect(start_new_game)
	box.add_child(button)


func _update_hud() -> void:
	level_label.text = "Niveau %d" % level
	coins_label.text = "Pièces %d/%d" % [coins_on_level - coins_left, coins_on_level]
	health_label.text = "Vie %d/%d" % [player.health, player.max_health]


func _flash(text: String) -> void:
	flash_label.text = text
	flash_label.modulate = Color(1, 1, 1, 1)
	flash_label.visible = true
	var tween := create_tween()
	tween.tween_interval(0.8)
	tween.tween_property(flash_label, "modulate:a", 0.0, 0.7)
	tween.tween_callback(func(): flash_label.visible = false)
