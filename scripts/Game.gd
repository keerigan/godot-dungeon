extends Node2D

## Boucle de jeu principale.
## Donjon 2D avec éclairage dynamique, particules, écran-titre, portail de
## sortie, bonus, plusieurs types d'ennemis et meilleur score sauvegardé.
## Tout est dessiné / généré par code : aucun asset binaire.

const TILE := 64
const COLS := 21
const ROWS := 31
const MAP_W := COLS * TILE
const MAP_H := ROWS * TILE
# Marges laissées à la caméra pour que les bords de l'arène passent sous le HUD
# (barre du haut, joystick / bouton objet en bas) au lieu d'être cachés.
const HUD_TOP_INSET := 136
const HUD_BOTTOM_INSET := 84
const SPAWN_CELL := Vector2i(COLS / 2, ROWS / 2)
const SAVE_PATH := "user://dungeon.cfg"

enum State { TITLE, PLAYING, DEAD }

## Succès (id, nom, description, compteur suivi, seuil).
const ACHIEVEMENTS: Array = [
	{"id": "kill1", "name": "Premier piège", "desc": "Éliminer un ennemi", "stat": "kills", "need": 1},
	{"id": "kill50", "name": "Exterminateur", "desc": "Éliminer 50 ennemis", "stat": "kills", "need": 50},
	{"id": "coins500", "name": "Magot", "desc": "Amasser 500 pièces au total", "stat": "coins", "need": 500},
	{"id": "lvl5", "name": "Explorateur", "desc": "Atteindre le niveau 5", "stat": "best_level", "need": 5},
	{"id": "lvl10", "name": "Vétéran", "desc": "Atteindre le niveau 10", "stat": "best_level", "need": 10},
	{"id": "boss1", "name": "Chasseur de boss", "desc": "Vaincre un boss", "stat": "bosses", "need": 1},
	{"id": "chest10", "name": "Pilleur", "desc": "Ouvrir 10 coffres", "stat": "chests", "need": 10},
	{"id": "nodmg", "name": "Sans une égratignure", "desc": "Finir un niveau sans perdre de cœur", "stat": "nodmg", "need": 1},
]

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
	{
		"name": "Désert",
		"ambient": Color(0.52, 0.44, 0.30),
		"floor_a": Color(0.20, 0.16, 0.11), "floor_b": Color(0.23, 0.19, 0.13),
		"wall_face": Color(0.36, 0.29, 0.18), "wall_top": Color(0.52, 0.43, 0.27),
		"wall_left": Color(0.44, 0.35, 0.22), "wall_bot": Color(0.16, 0.12, 0.07),
		"wall_right": Color(0.18, 0.14, 0.08), "seam": Color(0.12, 0.09, 0.05),
		"crack": Color(0.34, 0.27, 0.15),
		"torch": Color(1.0, 0.85, 0.45), "plight": Color(1.0, 0.93, 0.68),
	},
	{
		"name": "Améthyste",
		"ambient": Color(0.40, 0.30, 0.52),
		"floor_a": Color(0.14, 0.10, 0.18), "floor_b": Color(0.17, 0.12, 0.22),
		"wall_face": Color(0.28, 0.18, 0.36), "wall_top": Color(0.44, 0.28, 0.56),
		"wall_left": Color(0.35, 0.22, 0.45), "wall_bot": Color(0.12, 0.08, 0.16),
		"wall_right": Color(0.14, 0.09, 0.18), "seam": Color(0.10, 0.07, 0.13),
		"crack": Color(0.62, 0.40, 0.88),
		"torch": Color(0.85, 0.55, 1.0), "plight": Color(0.93, 0.80, 1.0),
	},
	{
		"name": "Abysse",
		"ambient": Color(0.24, 0.36, 0.40),
		"floor_a": Color(0.08, 0.14, 0.15), "floor_b": Color(0.10, 0.16, 0.18),
		"wall_face": Color(0.14, 0.24, 0.26), "wall_top": Color(0.24, 0.40, 0.42),
		"wall_left": Color(0.20, 0.33, 0.35), "wall_bot": Color(0.06, 0.11, 0.12),
		"wall_right": Color(0.08, 0.13, 0.14), "seam": Color(0.05, 0.09, 0.10),
		"crack": Color(0.32, 0.72, 0.68),
		"torch": Color(0.4, 0.95, 0.85), "plight": Color(0.72, 1.0, 0.95),
	},
]

var walls: Array = []
var _reachable: Dictionary = {}
var wall_bodies: Array[StaticBody2D] = []
var enemies: Array[Enemy] = []
var _pending_enemies: Array[Enemy] = []   ## Nés en cours de frame (division du slime)
var coins: Array[Coin] = []
var powerups: Array[Powerup] = []
var traps: Array[Trap] = []
var chests: Array[Chest] = []
var item_pickups: Array[ItemPickup] = []
var held_item: String = ""            ## Objet à usage unique en réserve ("" = aucun)
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
var _stats: Dictionary = {}          ## Compteurs cumulés (persistés)
var _unlocked: Dictionary = {}       ## Succès débloqués (persistés)
var _damage_free_level := true       ## Niveau en cours sans dégât ?
var gold := 0                        ## Porte-monnaie persistant (boutique)
var up_hearts := 0                   ## Amélioration : cœurs max en plus (0-4)
var up_shield := false               ## Amélioration : bouclier au départ
var up_lucky := false                ## Amélioration : plus de coffres
var _daily: Dictionary = {}          ## Défi du jour (choisi selon la date)
var _daily_done := false             ## Défi du jour déjà réussi aujourd'hui ?
var daily_done_key := ""             ## Clé du jour où le défi a été réussi
var _run_kills := 0                  ## Ennemis éliminés dans la partie en cours
var _run_chests := 0                 ## Coffres ouverts dans la partie en cours
var _run_grazes := 0                 ## Frôlements réussis dans la partie en cours
var _run_coins_collected := 0        ## Pièces ramassées dans la partie en cours

# Combo / frôlements
var _combo := 0                      ## Nombre de frôlements enchaînés
var _combo_tier := 1                 ## Palier de multiplicateur atteint
var _combo_timer := 0.0              ## Temps avant expiration du combo

# Skins (apparence de la lueur, achetés avec l'or)
const SKINS: Array = [
	{"id": "or", "name": "Lueur dorée", "shape": "orbe", "price": 0,
	 "body": Color(0.95, 0.85, 0.30), "rim": Color(0.35, 0.30, 0.10), "trail": Color(1.0, 0.8, 0.35)},
	{"id": "cyan", "name": "Robot", "shape": "robot", "price": 120,
	 "body": Color(0.55, 0.9, 1.0), "rim": Color(0.12, 0.32, 0.42), "trail": Color(0.4, 0.85, 1.0)},
	{"id": "violet", "name": "Fantôme", "shape": "fantome", "price": 180,
	 "body": Color(0.74, 0.56, 1.0), "rim": Color(0.26, 0.16, 0.42), "trail": Color(0.66, 0.46, 1.0)},
	{"id": "emeraude", "name": "Slime", "shape": "slime", "price": 240,
	 "body": Color(0.46, 0.95, 0.62), "rim": Color(0.12, 0.36, 0.22), "trail": Color(0.42, 0.95, 0.62)},
	{"id": "rose", "name": "Chaton", "shape": "chat", "price": 320,
	 "body": Color(1.0, 0.56, 0.82), "rim": Color(0.4, 0.16, 0.3), "trail": Color(1.0, 0.5, 0.8)},
	{"id": "spectre", "name": "Chevalier", "shape": "chevalier", "price": 500,
	 "body": Color(0.9, 0.93, 1.0), "rim": Color(0.42, 0.47, 0.57), "trail": Color(0.9, 0.95, 1.0)},
]
var owned_skins: Dictionary = {"or": true}   ## Skins débloqués
var current_skin := "or"                      ## Skin sélectionné
var _player_trail: CPUParticles2D             ## Traînée du héros (couleur du skin)

# Connexion quotidienne
var login_streak := 0                ## Jours de connexion consécutifs
var last_login_day := 0              ## Numéro de jour de la dernière connexion
var seen_tuto := false               ## Tutoriel du premier lancement déjà vu ?

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
var _freeze := 0.0                    ## Gel des ennemis (bonus de coffre)
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
var minimap: Minimap
var combo_label: Label
var flash_label: Label
var title_root: Control
var title_best: Label
var daily_label: Label
var vib_btn: Button
var theme_btn: Button
var gameover_root: Control
var gameover_score: Label
var achievements_root: Control
var pause_root: Control
var shop_root: Control
var _shop_list: VBoxContainer
var _shop_gold_label: Label
var skins_root: Control
var _skins_list: VBoxContainer
var _skins_gold_label: Label
var tutorial_root: Control
var title_gold: Label
var _ach_list: VBoxContainer
var _toast_label: Label
var _toast_queue: Array = []
var _toast_active := false
var item_btn: Button


func _ready() -> void:
	randomize()
	_load_prefs()
	_compute_daily()
	_unpack_theme()
	_light_tex = FX.make_light_texture(256)

	_ambient = CanvasModulate.new()
	_ambient.color = _c_ambient   # obscurité de base du donjon (selon thème)
	add_child(_ambient)

	_build_ui()
	_create_player()
	_apply_skin()
	Sfx.play_music()

	state = State.TITLE
	player.visible = false
	joystick.set_process_input(false)
	build_level()
	title_root.visible = true
	hud_root.visible = false

	_check_login_streak()
	if not seen_tuto:
		tutorial_root.visible = true


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_E or event.keycode == KEY_ENTER:
			_use_item()


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

	# Gel des ennemis (bonus)
	if _freeze > 0.0:
		_freeze -= delta
	var frozen_now := _freeze > 0.0
	for e in enemies:
		if is_instance_valid(e):
			e.frozen = frozen_now

	# Aimant à pièces (bonus)
	if player.magnet > 0.0:
		for c in coins:
			if is_instance_valid(c):
				var to_p := player.global_position - c.global_position
				if to_p.length() < 240.0:
					c.global_position += to_p.normalized() * 360.0 * delta

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
					_damage_free_level = false
					_reset_combo()
				break

	# Frôlements (combo) : un ennemi qui entre puis ressort de la zone proche
	# sans toucher le joueur rapporte un combo (multiplicateur de score).
	if player.invuln <= 0.0:
		for e in enemies:
			if not is_instance_valid(e) or e.frozen:
				continue
			var d := player.global_position.distance_to(e.global_position)
			var graze_r := Player.RADIUS + e.radius + 18.0
			var hit_r := Player.RADIUS + e.radius - 4.0
			var was_near: bool = e.get_meta("grz", false)
			if d <= graze_r and d > hit_r:
				e.set_meta("grz", true)
			elif was_near and d > graze_r:
				e.set_meta("grz", false)
				_register_graze((player.global_position + e.global_position) * 0.5)
	# Expiration du combo si plus de frôlement depuis un moment
	if _combo > 0:
		_combo_timer -= delta
		if _combo_timer <= 0.0:
			_reset_combo()

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
				_damage_free_level = false
				_reset_combo()
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
	if not _pending_enemies.is_empty():
		enemies.append_array(_pending_enemies)
		_pending_enemies.clear()


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
	player.max_health = 5 + up_hearts     # amélioration boutique
	held_item = ""
	_refresh_item_button()
	_run_kills = 0
	_run_chests = 0
	_run_grazes = 0
	_run_coins_collected = 0
	_reset_combo()
	_apply_skin()
	player.visible = true
	build_level()


func build_level() -> void:
	_clear_level()
	_apply_theme()          # met à jour le biome (mode Auto) avant de tout redessiner
	_generate_walls()
	_compute_reachable()
	_build_wall_bodies()
	_build_astar()
	_place_torches()
	_place_ambient_dust()

	player.global_position = _cell_to_world(SPAWN_CELL.x, SPAWN_CELL.y)
	player.reset()
	player.visible = (state == State.PLAYING)
	if state == State.PLAYING and up_shield:
		player.grant_shield(4.0)   # amélioration boutique : bouclier de départ

	var free_cells := _free_cells()
	free_cells.shuffle()

	# Portail à la case libre la plus éloignée du départ
	_spawn_portal(_farthest_cell(free_cells))

	# Pièges (de plus en plus nombreux, jamais collés au départ)
	var trap_count := mini(3 + int(level / 2), 9)
	for i in trap_count:
		if free_cells.is_empty():
			break
		var tc: Vector2i = free_cells.pop_back()
		if Vector2(tc).distance_to(Vector2(SPAWN_CELL)) >= 3.0:
			_spawn_trap(tc)

	# Pièces
	coins_on_level = mini(10 + level * 2, 44)
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

	# Coffre (plus fréquent avec l'amélioration boutique)
	if randf() < (0.85 if up_lucky else 0.6) and not free_cells.is_empty():
		_spawn_chest(free_cells.pop_back())

	# Objet à usage unique posé au sol
	if randf() < 0.5 and not free_cells.is_empty():
		_spawn_item(free_cells.pop_back())

	# Boss tous les 5 niveaux
	var is_boss_level := (level % 5 == 0)
	if is_boss_level:
		for c in free_cells:
			if Vector2(c).distance_to(Vector2(SPAWN_CELL)) >= 6.0:
				_spawn_boss(c)
				free_cells.erase(c)
				break

	# Ennemis variés, loin du héros (moins nombreux les niveaux de boss)
	var enemy_count := 3 if is_boss_level else mini(3 + level, 10)
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
		_flash(_level_banner())
		if level > int(_stats.get("best_level", 0)):
			_stats["best_level"] = level
		_damage_free_level = true
		_check_achievements()
		_check_daily()


func _level_banner() -> String:
	if level % 5 == 0:
		return "BOSS — Niveau %d" % level
	if theme_idx >= PALETTES.size():
		return "%s — Niveau %d" % [PALETTES[_effective_palette_index()]["name"], level]
	return "Niveau %d" % level


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
	if _damage_free_level:
		_stat_add("nodmg", 1)
		_check_achievements()
	level += 1
	build_level()


func _on_chest_opened(pos: Vector2) -> void:
	Sfx.play(Sfx.powerup)
	_vibrate(50)
	_burst(pos, Color(1.0, 0.85, 0.35), 22, 230.0, 0.6)
	match ["gold", "heal", "speed", "magnet", "freeze", "shield"][randi() % 6]:
		"gold":
			player.coins += 5
			player.coins_changed.emit(player.coins)
			_stat_add("coins", 5)
			_flash("Coffre : +5 or !")
		"heal":
			player.heal(2)
			_flash("Coffre : soin +2 !")
		"speed":
			player.grant_speed(8.0)
			_flash("Coffre : vitesse !")
		"magnet":
			player.grant_magnet(8.0)
			_flash("Coffre : aimant à pièces !")
		"freeze":
			_freeze = maxf(_freeze, 5.0)
			_flash("Coffre : ennemis gelés !")
		"shield":
			player.grant_shield(6.0)
			_flash("Coffre : bouclier !")
	_stat_add("chests", 1)
	_run_chests += 1
	_check_achievements()
	_check_daily()


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
	_reset_combo()
	var run := player.coins
	var new_best := run > best_score
	if new_best:
		best_score = run
	var best_line := "Nouveau record !  %d" % best_score if new_best else "Meilleur : %d" % best_score
	gameover_score.text = "Score : %d   ·   Niveau %d\n%s\nPièces ramassées : %d   ·   Frôlements : %d\nEnnemis éliminés : %d   ·   Coffres : %d\n+%d or en banque" % [
		run, level, best_line, _run_coins_collected, _run_grazes, _run_kills, _run_chests, run]
	_bank_run()
	gameover_root.visible = true


func _on_coin_collected(pos: Vector2) -> void:
	Sfx.play(Sfx.coin)
	player.add_coin()
	# Bonus de combo : le multiplicateur augmente la valeur des pièces
	var mult := _combo_mult()
	if mult > 1:
		player.coins += mult - 1
	_run_coins_collected += 1
	_stat_add("coins", 1)
	coins_left -= 1
	_burst(pos, Color(1.0, 0.85, 0.3), 8, 150.0, 0.4)
	_update_hud()
	_check_achievements()
	_check_daily()
	if coins_left <= 0:
		_open_exit()


# ---------------------------------------------------------------------------
# Combo / frôlements
# ---------------------------------------------------------------------------

func _combo_mult() -> int:
	return clampi(1 + _combo / 4, 1, 5)


func _register_graze(pos: Vector2) -> void:
	_combo += 1
	_run_grazes += 1
	_combo_timer = 6.0
	_stat_add("grazes", 1)
	_burst(pos, player.trail_color, 5, 90.0, 0.28)
	var tier := _combo_mult()
	if tier > _combo_tier:
		_combo_tier = tier
		_flash("Combo  x%d" % tier)
		Sfx.play(Sfx.powerup)
		_vibrate(25)
	_update_combo_label()


func _reset_combo() -> void:
	_combo = 0
	_combo_tier = 1
	_combo_timer = 0.0
	_update_combo_label()


func _update_combo_label() -> void:
	if combo_label == null:
		return
	if _combo <= 0:
		combo_label.visible = false
	else:
		combo_label.visible = true
		combo_label.text = "Combo %d   ·   score x%d" % [_combo, _combo_mult()]


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
	var boss := e.kind == Enemy.Kind.BOSS
	_burst(e.global_position, e.body_color, 26 if boss else 16, 300.0 if boss else 260.0, 0.6)
	Sfx.play(Sfx.enemy_die)
	if boss:
		Sfx.play(Sfx.level_up)
		player.coins += 25
		add_shake(12.0)
		_vibrate(200)
		_flash("Boss vaincu !  +25")
		_stat_add("coins", 25)
		_stat_add("bosses", 1)
	else:
		player.coins += 2
		add_shake(4.0)
		_vibrate(25)
		_stat_add("coins", 2)
	player.coins_changed.emit(player.coins)
	_stat_add("kills", 1)
	_run_kills += 1
	_check_achievements()
	_check_daily()
	if e.kind == Enemy.Kind.SPLITTER:
		_spawn_mini(e.global_position + Vector2(-16, 0))
		_spawn_mini(e.global_position + Vector2(16, 0))
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
	for ch in chests:
		if is_instance_valid(ch):
			ch.queue_free()
	chests.clear()
	for ip in item_pickups:
		if is_instance_valid(ip):
			ip.queue_free()
	item_pickups.clear()
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
	var blocks := 34 + level * 5
	if level % 5 == 0:
		blocks = int(blocks * 0.55)   # niveaux de boss plus aérés
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
	var count: int = min(12, candidates.size())
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


func _compute_reachable() -> void:
	_reachable.clear()
	var q: Array = [SPAWN_CELL]
	_reachable[SPAWN_CELL] = true
	var dirs := [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	while not q.is_empty():
		var c: Vector2i = q.pop_back()
		for d in dirs:
			var n: Vector2i = c + d
			if n.x < 0 or n.y < 0 or n.x >= COLS or n.y >= ROWS:
				continue
			if walls[n.y][n.x] or _reachable.has(n):
				continue
			_reachable[n] = true
			q.append(n)


func _free_cells() -> Array:
	var cells: Array = []
	for y in ROWS:
		for x in COLS:
			var c := Vector2i(x, y)
			if not walls[y][x] and c != SPAWN_CELL and _reachable.has(c):
				cells.append(c)
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


func _spawn_item(cell: Vector2i) -> void:
	var ip := ItemPickup.new()
	ip.kind = ["bomb", "freeze", "potion", "blink"][randi() % 4]
	ip.position = _cell_to_world(cell.x, cell.y)
	ip.picked.connect(_on_item_picked)
	add_child(ip)
	item_pickups.append(ip)


func _on_item_picked(kind: String) -> void:
	held_item = kind
	Sfx.play(Sfx.powerup)
	_vibrate(30)
	_flash("Objet : %s" % _item_name(kind))
	_refresh_item_button()


func _item_name(kind: String) -> String:
	match kind:
		"bomb": return "Bombe"
		"freeze": return "Gel"
		"potion": return "Potion"
		"blink": return "Saut"
	return kind


func _use_item() -> void:
	if state != State.PLAYING or held_item == "":
		return
	var kind := held_item
	held_item = ""
	_refresh_item_button()
	_vibrate(60)
	match kind:
		"bomb":
			Sfx.play(Sfx.enemy_die)
			add_shake(12.0)
			_burst(player.global_position, Color(1.0, 0.7, 0.3), 40, 340.0, 0.7)
			var survivors: Array[Enemy] = []
			for e in enemies:
				if not is_instance_valid(e):
					continue
				if player.global_position.distance_to(e.global_position) <= 210.0:
					if e.kind == Enemy.Kind.BOSS:
						e.hp -= 3
						e.take_hit(e.global_position - player.global_position)
						if e.hp <= 0:
							_kill_enemy(e)
						else:
							survivors.append(e)
					else:
						_kill_enemy(e)
				else:
					survivors.append(e)
			enemies = survivors
		"freeze":
			Sfx.play(Sfx.powerup)
			_freeze = maxf(_freeze, 6.0)
			_flash("Ennemis gelés !")
		"potion":
			Sfx.play(Sfx.powerup)
			player.heal(player.max_health)
			_burst(player.global_position, Color(0.9, 0.3, 0.4), 16, 170.0, 0.5)
		"blink":
			Sfx.play(Sfx.attack)
			var from := player.global_position
			var dest := from
			for i in range(1, 13):
				var p := from + player.facing * (i * 16.0)
				var c := _world_to_cell(p)
				if walls[c.y][c.x]:
					break
				dest = p
			player.global_position = dest
			_burst(from, Color(0.5, 0.9, 1.0), 14, 180.0, 0.4)
			_burst(dest, Color(0.5, 0.9, 1.0), 14, 180.0, 0.4)


func _refresh_item_button() -> void:
	if item_btn == null:
		return
	if held_item == "":
		item_btn.visible = false
	else:
		item_btn.visible = true
		item_btn.text = _item_name(held_item)


func _spawn_chest(cell: Vector2i) -> void:
	var ch := Chest.new()
	ch.position = _cell_to_world(cell.x, cell.y)
	ch.opened.connect(_on_chest_opened)
	add_child(ch)
	chests.append(ch)


func _spawn_portal(cell: Vector2i) -> void:
	portal = Portal.new()
	portal.position = _cell_to_world(cell.x, cell.y)
	portal.entered.connect(_on_portal_entered)
	add_child(portal)
	_exit_arrow.target = portal
	_exit_arrow.active = false


func _spawn_enemy(cell: Vector2i) -> void:
	# Palette d'ennemis qui s'enrichit avec le niveau
	var pool: Array = [Enemy.Kind.CHASER, Enemy.Kind.CHASER]
	if level >= 2:
		pool.append(Enemy.Kind.FAST)
	if level >= 3:
		pool.append(Enemy.Kind.TANK)
		pool.append(Enemy.Kind.ZIGZAG)
	if level >= 4:
		pool.append(Enemy.Kind.GHOST)
	if level >= 5:
		pool.append(Enemy.Kind.SPLITTER)
	_spawn_enemy_kind(cell, pool[randi() % pool.size()])


func _spawn_boss(cell: Vector2i) -> void:
	_spawn_enemy_kind(cell, Enemy.Kind.BOSS)


func _spawn_enemy_kind(cell: Vector2i, kind: int) -> void:
	var e := Enemy.new()
	e.setup(kind, level)
	e.position = _cell_to_world(cell.x, cell.y)
	e.target = player if state == State.PLAYING else null
	add_child(e)
	enemies.append(e)


## Petit ennemi rapide né de la division d'un slime.
func _spawn_mini(pos: Vector2) -> void:
	var e := Enemy.new()
	e.setup(Enemy.Kind.FAST, level)
	e.radius = 12.0
	e.position = pos
	e.target = player
	add_child(e)
	_pending_enemies.append(e)


func _create_player() -> void:
	player = Player.new()
	player.z_index = 3   # le héros est toujours au premier plan
	player.died.connect(_on_player_died)
	player.health_changed.connect(func(_c, _m): _update_hud())
	player.coins_changed.connect(func(_c): _update_hud())
	add_child(player)

	# Traînée du héros (couleur selon le skin)
	_player_trail = CPUParticles2D.new()
	_player_trail.amount = 20
	_player_trail.lifetime = 0.5
	_player_trail.local_coords = false   # les particules restent dans le monde -> traînée
	_player_trail.emitting = true
	_player_trail.spread = 6.0
	_player_trail.gravity = Vector2.ZERO
	_player_trail.initial_velocity_min = 0.0
	_player_trail.initial_velocity_max = 0.0
	_player_trail.scale_amount_min = 2.5
	_player_trail.scale_amount_max = 4.5
	_player_trail.z_index = 2
	player.add_child(_player_trail)

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
	camera.limit_top = -HUD_TOP_INSET
	camera.limit_right = MAP_W
	camera.limit_bottom = MAP_H + HUD_BOTTOM_INSET
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
	# Fond sombre débordant : couvre les marges hors-carte dégagées pour le HUD
	# afin qu'elles restent noires (et non de la couleur d'effacement par défaut).
	draw_rect(Rect2(-220, -220, MAP_W + 440, MAP_H + 440), Color(0.02, 0.02, 0.045))
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
	level_label.position = Vector2(78, 14)   # laisse la place au bouton pause
	coins_label = _make_label("0 / 0 pièces", HORIZONTAL_ALIGNMENT_CENTER)
	score_label = _make_label("Score 0", HORIZONTAL_ALIGNMENT_RIGHT)

	var pause_btn := Button.new()
	pause_btn.text = "II"
	pause_btn.add_theme_font_size_override("font_size", 26)
	pause_btn.position = Vector2(14, 12)
	pause_btn.size = Vector2(54, 50)
	pause_btn.focus_mode = Control.FOCUS_NONE
	pause_btn.pressed.connect(_pause)
	hud_root.add_child(pause_btn)

	hearts = HeartsBar.new()
	hearts.position = Vector2(34, 84)
	hud_root.add_child(hearts)

	minimap = Minimap.new()
	minimap.game = self
	minimap.position = Vector2(720 - Minimap.MM_W - 14, 128)
	hud_root.add_child(minimap)

	# Bouton pour masquer/afficher la mini-carte (elle peut cacher des pièces)
	var map_toggle := Button.new()
	map_toggle.text = "Carte"
	map_toggle.add_theme_font_size_override("font_size", 18)
	map_toggle.size = Vector2(84, 34)
	map_toggle.position = Vector2(720 - 98, 72)
	map_toggle.focus_mode = Control.FOCUS_NONE
	map_toggle.modulate = Color(1, 1, 1, 0.8)
	map_toggle.pressed.connect(func() -> void: minimap.visible = not minimap.visible)
	hud_root.add_child(map_toggle)

	# Indicateur de combo (frôlements) : visible seulement pendant un combo
	combo_label = Label.new()
	combo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	combo_label.add_theme_font_size_override("font_size", 24)
	combo_label.add_theme_color_override("font_color", Color(1.0, 0.72, 0.3))
	combo_label.size = Vector2(720, 34)
	combo_label.position = Vector2(0, 122)
	combo_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	combo_label.visible = false
	hud_root.add_child(combo_label)

	flash_label = Label.new()
	flash_label.add_theme_font_size_override("font_size", 54)
	flash_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	flash_label.size = Vector2(720, 80)
	flash_label.position = Vector2(0, 360)
	flash_label.visible = false
	hud_root.add_child(flash_label)

	joystick = VirtualJoystick.new()
	hud_root.add_child(joystick)

	# Bouton d'utilisation d'objet (bas-droite), visible seulement si on en tient un
	item_btn = Button.new()
	item_btn.add_theme_font_size_override("font_size", 26)
	item_btn.size = Vector2(150, 150)
	item_btn.position = Vector2(540, 1070)
	item_btn.focus_mode = Control.FOCUS_NONE
	item_btn.modulate = Color(1, 1, 1, 0.92)
	item_btn.visible = false
	item_btn.pressed.connect(_use_item)
	hud_root.add_child(item_btn)

	# Notification de succès (visible partout)
	_toast_label = Label.new()
	_toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast_label.add_theme_font_size_override("font_size", 26)
	_toast_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.4))
	_toast_label.size = Vector2(720, 40)
	_toast_label.position = Vector2(0, 130)
	_toast_label.visible = false
	ui_layer.add_child(_toast_label)

	_build_title_ui()
	_build_gameover_ui()
	_build_achievements_ui()
	_build_pause_ui()
	_build_shop_ui()
	_build_skins_ui()
	_build_tutorial_ui()


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
	title.text = "GLOOMRUNNER"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 62)
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

	title_gold = Label.new()
	title_gold.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_gold.add_theme_font_size_override("font_size", 22)
	title_gold.add_theme_color_override("font_color", Color(1.0, 0.85, 0.4))
	box.add_child(title_gold)

	daily_label = Label.new()
	daily_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	daily_label.add_theme_font_size_override("font_size", 20)
	box.add_child(daily_label)

	var play := Button.new()
	play.text = "  ▶  JOUER  "
	play.add_theme_font_size_override("font_size", 38)
	play.custom_minimum_size = Vector2(300, 90)
	play.focus_mode = Control.FOCUS_NONE
	play.pressed.connect(start_game)
	box.add_child(play)

	var hint := Label.new()
	hint.text = "Déplace-toi, esquive, ramasse l'or, trouve la sortie"
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

	var ach_btn := Button.new()
	ach_btn.text = "Succès"
	ach_btn.add_theme_font_size_override("font_size", 24)
	ach_btn.custom_minimum_size = Vector2(300, 58)
	ach_btn.focus_mode = Control.FOCUS_NONE
	ach_btn.pressed.connect(_open_achievements)
	box.add_child(ach_btn)

	var shop_btn := Button.new()
	shop_btn.text = "Boutique"
	shop_btn.add_theme_font_size_override("font_size", 24)
	shop_btn.custom_minimum_size = Vector2(300, 58)
	shop_btn.focus_mode = Control.FOCUS_NONE
	shop_btn.pressed.connect(_open_shop)
	box.add_child(shop_btn)

	var skins_btn := Button.new()
	skins_btn.text = "Apparence"
	skins_btn.add_theme_font_size_override("font_size", 24)
	skins_btn.custom_minimum_size = Vector2(300, 58)
	skins_btn.focus_mode = Control.FOCUS_NONE
	skins_btn.pressed.connect(_open_skins)
	box.add_child(skins_btn)

	_refresh_best_labels()


func _build_achievements_ui() -> void:
	achievements_root = Control.new()
	achievements_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	achievements_root.mouse_filter = Control.MOUSE_FILTER_STOP
	achievements_root.visible = false
	ui_layer.add_child(achievements_root)

	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.03, 0.07, 0.9)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	achievements_root.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	achievements_root.add_child(center)

	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 14)
	center.add_child(box)

	var title := Label.new()
	title.text = "SUCCÈS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 48)
	title.add_theme_color_override("font_color", Color(0.98, 0.82, 0.35))
	box.add_child(title)

	_ach_list = VBoxContainer.new()
	_ach_list.add_theme_constant_override("separation", 8)
	box.add_child(_ach_list)

	var close := Button.new()
	close.text = "  Fermer  "
	close.add_theme_font_size_override("font_size", 28)
	close.custom_minimum_size = Vector2(220, 64)
	close.focus_mode = Control.FOCUS_NONE
	close.pressed.connect(func(): achievements_root.visible = false)
	box.add_child(close)


func _build_shop_ui() -> void:
	shop_root = Control.new()
	shop_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	shop_root.mouse_filter = Control.MOUSE_FILTER_STOP
	shop_root.visible = false
	ui_layer.add_child(shop_root)

	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.03, 0.07, 0.92)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	shop_root.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	shop_root.add_child(center)

	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 16)
	center.add_child(box)

	var title := Label.new()
	title.text = "BOUTIQUE"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 48)
	title.add_theme_color_override("font_color", Color(0.98, 0.82, 0.35))
	box.add_child(title)

	_shop_gold_label = Label.new()
	_shop_gold_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_shop_gold_label.add_theme_font_size_override("font_size", 26)
	_shop_gold_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.4))
	box.add_child(_shop_gold_label)

	_shop_list = VBoxContainer.new()
	_shop_list.add_theme_constant_override("separation", 10)
	box.add_child(_shop_list)

	var hint := Label.new()
	hint.text = "L'or gagné en jeu est mis en banque à la fin d'une partie."
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 16)
	hint.add_theme_color_override("font_color", Color(0.7, 0.7, 0.75))
	box.add_child(hint)

	var close := Button.new()
	close.text = "  Fermer  "
	close.add_theme_font_size_override("font_size", 28)
	close.custom_minimum_size = Vector2(220, 64)
	close.focus_mode = Control.FOCUS_NONE
	close.pressed.connect(func(): shop_root.visible = false)
	box.add_child(close)


func _shop_cost(id: String) -> int:
	match id:
		"hearts": return 25 * (up_hearts + 1)
		"shield": return 60
		"lucky": return 50
	return 0


func _shop_maxed(id: String) -> bool:
	match id:
		"hearts": return up_hearts >= 4
		"shield": return up_shield
		"lucky": return up_lucky
	return false


func _shop_row_text(id: String) -> String:
	match id:
		"hearts": return "Cœur max +1  (%d/4)" % up_hearts
		"shield": return "Bouclier au départ"
		"lucky": return "Plus de coffres"
	return id


func _buy(id: String) -> void:
	if _shop_maxed(id) or gold < _shop_cost(id):
		return
	gold -= _shop_cost(id)
	match id:
		"hearts": up_hearts += 1
		"shield": up_shield = true
		"lucky": up_lucky = true
	Sfx.play(Sfx.powerup)
	_vibrate(30)
	_save_prefs()
	_open_shop()


func _open_shop() -> void:
	_refresh_best_labels()
	for c in _shop_list.get_children():
		c.queue_free()
	for id in ["hearts", "shield", "lucky"]:
		var maxed := _shop_maxed(id)
		var cost := _shop_cost(id)
		var b := Button.new()
		b.text = _shop_row_text(id) + ("   —   ACHETÉ" if maxed else "   —   %d or" % cost)
		b.add_theme_font_size_override("font_size", 22)
		b.custom_minimum_size = Vector2(460, 62)
		b.focus_mode = Control.FOCUS_NONE
		b.disabled = maxed or gold < cost
		b.pressed.connect(_buy.bind(id))
		_shop_list.add_child(b)
	shop_root.visible = true


# ---------------------------------------------------------------------------
# Apparence (skins de la lueur)
# ---------------------------------------------------------------------------

func _skin_by_id(id: String) -> Dictionary:
	for s in SKINS:
		if s["id"] == id:
			return s
	return SKINS[0]


func _apply_skin() -> void:
	var s := _skin_by_id(current_skin)
	if player != null:
		player.body_color = s["body"]
		player.rim_color = s["rim"]
		player.trail_color = s["trail"]
		player.shape = s.get("shape", "orbe")
		player.queue_redraw()
	if _player_trail != null:
		var t: Color = s["trail"]
		_player_trail.color = Color(t.r, t.g, t.b, 0.45)


func _build_skins_ui() -> void:
	skins_root = Control.new()
	skins_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	skins_root.mouse_filter = Control.MOUSE_FILTER_STOP
	skins_root.visible = false
	ui_layer.add_child(skins_root)

	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.03, 0.07, 0.92)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	skins_root.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	skins_root.add_child(center)

	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 16)
	center.add_child(box)

	var title := Label.new()
	title.text = "APPARENCE"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 48)
	title.add_theme_color_override("font_color", Color(0.98, 0.82, 0.35))
	box.add_child(title)

	_skins_gold_label = Label.new()
	_skins_gold_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_skins_gold_label.add_theme_font_size_override("font_size", 26)
	_skins_gold_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.4))
	box.add_child(_skins_gold_label)

	_skins_list = VBoxContainer.new()
	_skins_list.add_theme_constant_override("separation", 10)
	box.add_child(_skins_list)

	var close := Button.new()
	close.text = "  Fermer  "
	close.add_theme_font_size_override("font_size", 28)
	close.custom_minimum_size = Vector2(220, 64)
	close.focus_mode = Control.FOCUS_NONE
	close.pressed.connect(func(): skins_root.visible = false)
	box.add_child(close)


func _open_skins() -> void:
	_skins_gold_label.text = "Or : %d" % gold
	for c in _skins_list.get_children():
		c.queue_free()
	for s in SKINS:
		var id: String = s["id"]
		var owned: bool = owned_skins.has(id)
		var selected: bool = current_skin == id
		var price: int = int(s["price"])
		var b := Button.new()
		var suffix := ""
		if selected:
			suffix = "   —   SÉLECTIONNÉ"
		elif owned:
			suffix = "   —   Choisir"
		else:
			suffix = "   —   %d or" % price
		b.text = s["name"] + suffix
		b.add_theme_font_size_override("font_size", 22)
		b.custom_minimum_size = Vector2(460, 62)
		b.focus_mode = Control.FOCUS_NONE
		b.add_theme_color_override("font_color", s["body"])
		b.disabled = selected or (not owned and gold < price)
		b.pressed.connect(_skin_action.bind(id))
		_skins_list.add_child(b)
	skins_root.visible = true


func _skin_action(id: String) -> void:
	var s := _skin_by_id(id)
	if owned_skins.has(id):
		current_skin = id
	else:
		if gold < int(s["price"]):
			return
		gold -= int(s["price"])
		owned_skins[id] = true
		current_skin = id
		Sfx.play(Sfx.powerup)
	_vibrate(30)
	_apply_skin()
	_save_prefs()
	_open_skins()


# ---------------------------------------------------------------------------
# Tutoriel (premier lancement) & connexion quotidienne
# ---------------------------------------------------------------------------

func _build_tutorial_ui() -> void:
	tutorial_root = Control.new()
	tutorial_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	tutorial_root.mouse_filter = Control.MOUSE_FILTER_STOP
	tutorial_root.visible = false
	ui_layer.add_child(tutorial_root)

	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.03, 0.07, 0.95)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	tutorial_root.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	tutorial_root.add_child(center)

	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 22)
	center.add_child(box)

	var title := Label.new()
	title.text = "BIENVENUE"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 46)
	title.add_theme_color_override("font_color", Color(0.98, 0.82, 0.35))
	box.add_child(title)

	var body := Label.new()
	body.text = "• Déplace-toi : pose le doigt n'importe où et glisse.\n" \
		+ "• Ramasse tout l'or pour ouvrir la sortie.\n" \
		+ "• Rejoins le portail pour passer au niveau suivant.\n" \
		+ "• Esquive les ennemis — frôle-les de près pour\n" \
		+ "   enchaîner un COMBO et gagner plus de score.\n" \
		+ "• Dépense ton or en boutique et en apparences."
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	body.add_theme_font_size_override("font_size", 24)
	body.add_theme_color_override("font_color", Color(0.88, 0.88, 0.92))
	box.add_child(body)

	var ok := Button.new()
	ok.text = "  Compris !  "
	ok.add_theme_font_size_override("font_size", 30)
	ok.custom_minimum_size = Vector2(280, 76)
	ok.focus_mode = Control.FOCUS_NONE
	ok.pressed.connect(_close_tutorial)
	box.add_child(ok)


func _close_tutorial() -> void:
	tutorial_root.visible = false
	seen_tuto = true
	_save_prefs()


func _day_number() -> int:
	var d := Time.get_date_dict_from_system()
	var unix := Time.get_unix_time_from_datetime_dict({
		"year": d.year, "month": d.month, "day": d.day,
		"hour": 0, "minute": 0, "second": 0})
	return int(unix / 86400)


func _check_login_streak() -> void:
	var today := _day_number()
	if last_login_day == today:
		return   # déjà connecté aujourd'hui
	if last_login_day == today - 1:
		login_streak += 1
	else:
		login_streak = 1
	last_login_day = today
	var reward := 15 + 5 * mini(login_streak, 7)   # 20..50 or
	gold += reward
	_save_prefs()
	_queue_toast("Jour %d de connexion !  +%d or" % [login_streak, reward])


func _build_pause_ui() -> void:
	pause_root = Control.new()
	pause_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	pause_root.mouse_filter = Control.MOUSE_FILTER_STOP
	pause_root.visible = false
	pause_root.process_mode = Node.PROCESS_MODE_ALWAYS   # actif même en pause
	ui_layer.add_child(pause_root)

	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.03, 0.07, 0.78)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	pause_root.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	pause_root.add_child(center)

	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 22)
	center.add_child(box)

	var title := Label.new()
	title.text = "PAUSE"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 56)
	title.add_theme_color_override("font_color", Color(0.98, 0.82, 0.35))
	box.add_child(title)

	for entry in [["  Reprendre  ", _resume], ["  Recommencer  ", _restart], ["  Quitter  ", _quit_to_title]]:
		var b := Button.new()
		b.text = entry[0]
		b.add_theme_font_size_override("font_size", 30)
		b.custom_minimum_size = Vector2(280, 70)
		b.focus_mode = Control.FOCUS_NONE
		b.pressed.connect(entry[1])
		box.add_child(b)


func _pause() -> void:
	if state != State.PLAYING or pause_root.visible:
		return
	pause_root.visible = true
	get_tree().paused = true


func _resume() -> void:
	get_tree().paused = false
	pause_root.visible = false


func _restart() -> void:
	_resume()
	start_game()


func _quit_to_title() -> void:
	_resume()
	_bank_run()          # on garde l'or gagné pendant la partie
	_goto_title()


func _goto_title() -> void:
	state = State.TITLE
	player.visible = false
	joystick.set_process_input(false)
	joystick.output = Vector2.ZERO
	hud_root.visible = false
	gameover_root.visible = false
	build_level()
	title_root.visible = true
	_refresh_best_labels()
	if theme_btn != null:
		theme_btn.text = _theme_label()


func _open_achievements() -> void:
	for c in _ach_list.get_children():
		c.queue_free()
	for a in ACHIEVEMENTS:
		var done: bool = _unlocked.has(a["id"])
		var prog := ""
		if not done:
			var cur: int = mini(int(_stats.get(a["stat"], 0)), int(a["need"]))
			prog = "   (%d/%d)" % [cur, int(a["need"])]
		var l := Label.new()
		l.text = ("[x]  " if done else "[  ]  ") + a["name"] + " — " + a["desc"] + prog
		l.add_theme_font_size_override("font_size", 20)
		l.add_theme_color_override("font_color",
			Color(1.0, 0.85, 0.4) if done else Color(0.5, 0.5, 0.56))
		_ach_list.add_child(l)
	achievements_root.visible = true


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
	if title_gold != null:
		title_gold.text = "Or : %d" % gold
	if _shop_gold_label != null:
		_shop_gold_label.text = "Or disponible : %d" % gold
	_refresh_daily_label()


func _bank_run() -> void:
	if player.coins > 0:
		gold += player.coins
		player.coins = 0
		_save_prefs()


# ---------------------------------------------------------------------------
# Défi du jour
# ---------------------------------------------------------------------------

func _daily_key() -> String:
	var d := Time.get_date_dict_from_system()
	return "%04d%02d%02d" % [d.year, d.month, d.day]


## Choisit le défi du jour (déterministe pour toute la journée).
func _compute_daily() -> void:
	var pool: Array = [
		{"text": "Atteins le niveau 5", "stat": "level", "goal": 5},
		{"text": "Ramasse 45 pièces en une partie", "stat": "coins", "goal": 45},
		{"text": "Élimine 8 ennemis en une partie", "stat": "kills", "goal": 8},
		{"text": "Ouvre 3 coffres en une partie", "stat": "chests", "goal": 3},
		{"text": "Atteins le niveau 7", "stat": "level", "goal": 7},
	]
	var key := _daily_key()
	var rng := RandomNumberGenerator.new()
	rng.seed = int(key)
	_daily = pool[rng.randi() % pool.size()]
	_daily_done = (daily_done_key == key)


func _daily_progress() -> int:
	match _daily.get("stat", ""):
		"level": return level
		"coins": return player.coins
		"kills": return _run_kills
		"chests": return _run_chests
	return 0


func _check_daily() -> void:
	if _daily_done or _daily.is_empty() or state != State.PLAYING:
		return
	if _daily_progress() >= int(_daily["goal"]):
		_daily_done = true
		daily_done_key = _daily_key()
		gold += 50
		_save_prefs()
		_queue_toast("Défi du jour réussi !  +50 or")
		_refresh_daily_label()


func _refresh_daily_label() -> void:
	if daily_label == null:
		return
	if _daily.is_empty():
		daily_label.text = ""
		return
	if _daily_done:
		daily_label.text = "Défi du jour : %s  (fait)" % _daily["text"]
		daily_label.add_theme_color_override("font_color", Color(0.5, 0.9, 0.5))
	else:
		daily_label.text = "Défi du jour : %s  (+50 or)" % _daily["text"]
		daily_label.add_theme_color_override("font_color", Color(0.9, 0.8, 0.5))


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
		theme_idx = clampi(int(cfg.get_value("options", "theme", 0)), 0, PALETTES.size())
		var st = cfg.get_value("stats", "data", {})
		if st is Dictionary:
			_stats = st.duplicate()
		for id in cfg.get_value("achievements", "unlocked", []):
			_unlocked[id] = true
		gold = int(cfg.get_value("shop", "gold", 0))
		up_hearts = clampi(int(cfg.get_value("shop", "hearts", 0)), 0, 4)
		up_shield = bool(cfg.get_value("shop", "shield", false))
		up_lucky = bool(cfg.get_value("shop", "lucky", false))
		daily_done_key = str(cfg.get_value("daily", "done_key", ""))
		owned_skins = {"or": true}
		for id in cfg.get_value("skins", "owned", ["or"]):
			owned_skins[id] = true
		current_skin = str(cfg.get_value("skins", "current", "or"))
		if not owned_skins.has(current_skin):
			current_skin = "or"
		login_streak = int(cfg.get_value("daily", "streak", 0))
		last_login_day = int(cfg.get_value("daily", "last_day", 0))
		seen_tuto = bool(cfg.get_value("options", "seen_tuto", false))


func _save_prefs() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("score", "best", best_score)
	cfg.set_value("options", "vibration", vibration_enabled)
	cfg.set_value("options", "theme", theme_idx)
	cfg.set_value("stats", "data", _stats)
	cfg.set_value("achievements", "unlocked", _unlocked.keys())
	cfg.set_value("shop", "gold", gold)
	cfg.set_value("shop", "hearts", up_hearts)
	cfg.set_value("shop", "shield", up_shield)
	cfg.set_value("shop", "lucky", up_lucky)
	cfg.set_value("daily", "done_key", daily_done_key)
	cfg.set_value("skins", "owned", owned_skins.keys())
	cfg.set_value("skins", "current", current_skin)
	cfg.set_value("daily", "streak", login_streak)
	cfg.set_value("daily", "last_day", last_login_day)
	cfg.set_value("options", "seen_tuto", seen_tuto)
	cfg.save(SAVE_PATH)
	_refresh_best_labels()


func _stat_add(key: String, n: int) -> void:
	_stats[key] = int(_stats.get(key, 0)) + n


func _check_achievements() -> void:
	var newly: Array = []
	for a in ACHIEVEMENTS:
		if _unlocked.has(a["id"]):
			continue
		if int(_stats.get(a["stat"], 0)) >= int(a["need"]):
			_unlocked[a["id"]] = true
			newly.append(a)
	if not newly.is_empty():
		_save_prefs()
		for a in newly:
			_queue_toast("Succès : " + a["name"])


# ---------------------------------------------------------------------------
# Notifications (toasts)
# ---------------------------------------------------------------------------

func _queue_toast(text: String) -> void:
	_toast_queue.append(text)
	if not _toast_active:
		_show_next_toast()


func _show_next_toast() -> void:
	if _toast_queue.is_empty():
		_toast_active = false
		return
	_toast_active = true
	_toast_label.text = str(_toast_queue.pop_front())
	_toast_label.visible = true
	_toast_label.modulate = Color(1, 1, 1, 0)
	_vibrate(30)
	var tw := create_tween()
	tw.tween_property(_toast_label, "modulate:a", 1.0, 0.25)
	tw.tween_interval(1.7)
	tw.tween_property(_toast_label, "modulate:a", 0.0, 0.4)
	tw.tween_callback(_show_next_toast)


## Indice de palette réellement utilisé (gère le mode "Auto" = biomes).
func _effective_palette_index() -> int:
	if theme_idx < PALETTES.size():
		return theme_idx
	return int((level - 1) / 2) % PALETTES.size()   # change de biome tous les 2 niveaux


## Copie la palette courante dans les variables de couleur (rapide pour _draw).
func _unpack_theme() -> void:
	var p: Dictionary = PALETTES[_effective_palette_index()]
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
	theme_idx = (theme_idx + 1) % (PALETTES.size() + 1)   # +1 pour le mode "Auto"
	_apply_theme()
	_save_prefs()
	if theme_btn != null:
		theme_btn.text = _theme_label()


func _theme_label() -> String:
	if theme_idx >= PALETTES.size():
		return "Thème : Auto (biomes)  »"
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
