class_name Coin
extends Area2D

## Une pièce à collecter. Émet `collected` quand le joueur la touche.

signal collected

const RADIUS := 12.0

var _spin := 0.0

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2   # Détecte le joueur (couche 2)
	monitoring = true
	var shape := CircleShape2D.new()
	shape.radius = RADIUS
	var cs := CollisionShape2D.new()
	cs.shape = shape
	add_child(cs)
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	_spin += delta * 3.0
	queue_redraw()

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		# Le score est géré par Game via le signal `collected`.
		collected.emit()
		queue_free()

func _draw() -> void:
	# Halo doux
	draw_circle(Vector2.ZERO, RADIUS + 4.0, Color(1.0, 0.85, 0.3, 0.14))
	# Effet de rotation : la pièce s'aplatit horizontalement
	var w := absf(cos(_spin)) * RADIUS + 2.0
	draw_circle(Vector2.ZERO, RADIUS, Color(0.95, 0.78, 0.20))
	draw_arc(Vector2.ZERO, RADIUS, 0.0, TAU, 20, Color(0.72, 0.52, 0.12), 2.0)
	# Reflet intérieur, largeur variable pour simuler la rotation
	draw_circle(Vector2.ZERO, maxf(w * 0.55, 2.0), Color(1.0, 0.92, 0.5))
	# Éclat brillant qui tourne
	var g := Vector2(cos(_spin * 0.7), sin(_spin * 0.7)) * (RADIUS * 0.4)
	draw_line(g - Vector2(3, 0), g + Vector2(3, 0), Color(1, 1, 1, 0.9), 1.5)
	draw_line(g - Vector2(0, 3), g + Vector2(0, 3), Color(1, 1, 1, 0.9), 1.5)
