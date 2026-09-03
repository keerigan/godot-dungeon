class_name ExitArrow
extends Node2D

## Petite flèche qui tourne autour du héros et pointe vers le portail de sortie.
## Discrète tant que la sortie est fermée, lumineuse et pulsante une fois ouverte.
## Placée en enfant du héros (suit sa position, reste dans son halo de lumière).

const RADIUS := 48.0        ## Distance de la flèche au centre du héros
const HIDE_DIST := 96.0     ## Masquée quand le portail est tout proche

var target: Node2D          ## Le portail à indiquer
var active := false         ## true quand la sortie est ouverte
var enabled := false        ## activé uniquement pendant une partie
var _t := 0.0


func _process(delta: float) -> void:
	_t += delta
	var ok := enabled and target != null and is_instance_valid(target)
	visible = ok
	if ok:
		rotation = (target.global_position - global_position).angle()
		queue_redraw()


func _draw() -> void:
	if target == null or not is_instance_valid(target):
		return
	if global_position.distance_to(target.global_position) < HIDE_DIST:
		return

	var col := Color(0.55, 0.9, 1.0) if active else Color(0.6, 0.82, 1.0, 0.85)
	var pulse := (sin(_t * 7.0) * 0.5 + 0.5) if active else 0.0
	var reach := RADIUS + pulse * 8.0   # avance/recule quand la sortie est ouverte

	# Tout est dessiné le long de l'axe local +X (orienté vers le portail)
	var shaft_a := Vector2(reach - 10.0, 0)
	var shaft_b := Vector2(reach + 6.0, 0)
	draw_line(shaft_a, shaft_b, col, 4.0)
	draw_colored_polygon(PackedVector2Array([
		Vector2(reach + 18.0, 0),
		Vector2(reach + 4.0, -9.0),
		Vector2(reach + 4.0, 9.0),
	]), col)
