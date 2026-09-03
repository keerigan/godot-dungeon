class_name Trap
extends Node2D

## Piège à pics : les pics sortent par cycles. Ils sont télégraphiés (on les
## voit monter) et ne blessent que lorsqu'ils sont sortis.

const PERIOD := 2.2          ## Durée d'un cycle complet (secondes)
const OUT_START := 1.5       ## Début de la sortie des pics dans le cycle
const OUT_LEN := 0.6         ## Durée de la sortie
const DANGER := 0.55         ## Seuil d'extension au-delà duquel ça blesse
const SPIKE_H := 22.0

var _t := 0.0


func _ready() -> void:
	_t = randf() * PERIOD     # déphasage aléatoire entre pièges


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func extension() -> float:
	var x := fmod(_t, PERIOD)
	if x < OUT_START or x > OUT_START + OUT_LEN:
		return 0.0
	return sin((x - OUT_START) / OUT_LEN * PI)


func is_dangerous() -> bool:
	return extension() > DANGER


func _draw() -> void:
	# Plaque de base (toujours visible pour repérer le piège)
	draw_rect(Rect2(-30, -30, 60, 60), Color(0.11, 0.10, 0.13))
	draw_rect(Rect2(-30, -30, 60, 60), Color(0.22, 0.20, 0.26), false, 2.0)

	var e := extension()
	if e <= 0.01:
		# Fentes des pics au repos
		for sx in [-18.0, 0.0, 18.0]:
			draw_rect(Rect2(sx - 8.0, 18.0, 16.0, 4.0), Color(0.05, 0.05, 0.07))
		return

	var danger := e > DANGER
	var metal := Color(0.85, 0.86, 0.92) if not danger else Color(1.0, 0.55, 0.5)
	var edge := Color(0.5, 0.5, 0.58) if not danger else Color(0.7, 0.2, 0.2)
	var h := SPIKE_H * e
	for sx in [-18.0, 0.0, 18.0]:
		var pts := PackedVector2Array([
			Vector2(sx - 8.0, 22.0),
			Vector2(sx + 8.0, 22.0),
			Vector2(sx, 22.0 - h),
		])
		draw_colored_polygon(pts, metal)
		draw_polyline(PackedVector2Array([pts[0], pts[2], pts[1]]), edge, 1.5)
