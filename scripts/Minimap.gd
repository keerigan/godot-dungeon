class_name Minimap
extends Node2D

## Mini-carte du donjon (coin de l'écran). Lit l'état du jeu via `game`.

var game            ## Référence au nœud Game (accès dynamique)

const MM_W := 156.0   ## Largeur de la mini-carte (px écran)


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if game == null:
		return
	var walls = game.walls
	if walls.is_empty():
		return
	var rows: int = walls.size()
	var cols: int = walls[0].size()
	var cw: float = MM_W / cols
	var mm_h: float = cw * rows
	var tile: float = game.TILE

	# Fond
	draw_rect(Rect2(-5, -5, MM_W + 10, mm_h + 10), Color(0.03, 0.03, 0.06, 0.62))
	draw_rect(Rect2(-5, -5, MM_W + 10, mm_h + 10), Color(1, 1, 1, 0.12), false, 1.0)

	# Murs
	for y in rows:
		for x in cols:
			if walls[y][x]:
				draw_rect(Rect2(x * cw, y * cw, cw + 0.6, cw + 0.6), Color(0.55, 0.56, 0.66, 0.9))

	# Pièces
	for c in game.coins:
		if is_instance_valid(c):
			draw_circle(_to_mm(c.position, tile, cw), 1.5, Color(1.0, 0.85, 0.3))

	# Pièges
	for t in game.traps:
		if is_instance_valid(t):
			var p := _to_mm(t.position, tile, cw)
			draw_rect(Rect2(p - Vector2(cw * 0.45, cw * 0.45), Vector2(cw * 0.9, cw * 0.9)),
				Color(0.85, 0.4, 0.4, 0.7))

	# Portail
	if is_instance_valid(game.portal):
		var col := Color(0.5, 0.9, 1.0) if game.portal.active else Color(0.4, 0.6, 0.8)
		draw_circle(_to_mm(game.portal.position, tile, cw), 3.2, col)

	# Ennemis
	for e in game.enemies:
		if is_instance_valid(e):
			draw_circle(_to_mm(e.global_position, tile, cw), 2.2, Color(0.95, 0.32, 0.30))

	# Héros
	if is_instance_valid(game.player):
		var pp := _to_mm(game.player.global_position, tile, cw)
		draw_circle(pp, 2.6, Color(1.0, 1.0, 0.65))
		draw_arc(pp, 3.8, 0.0, TAU, 12, Color(1, 1, 1, 0.85), 1.0)


func _to_mm(world: Vector2, tile: float, cw: float) -> Vector2:
	return Vector2(world.x / tile * cw, world.y / tile * cw)
