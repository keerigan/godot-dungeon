class_name Enemy
extends CharacterBody2D

## Un ennemi qui poursuit lentement le joueur.

const RADIUS := 19.0

var speed := 120.0
var target: Node2D

func _ready() -> void:
	collision_layer = 4   # Couche "ennemis"
	collision_mask = 1    # Entre en collision uniquement avec les murs
	var shape := CircleShape2D.new()
	shape.radius = RADIUS
	var cs := CollisionShape2D.new()
	cs.shape = shape
	add_child(cs)

func _physics_process(_delta: float) -> void:
	if target != null and is_instance_valid(target):
		var to_target := target.global_position - global_position
		if to_target.length() > 1.0:
			velocity = to_target.normalized() * speed
		else:
			velocity = Vector2.ZERO
		move_and_slide()

func _draw() -> void:
	draw_circle(Vector2.ZERO, RADIUS, Color(0.87, 0.33, 0.31))
	draw_arc(Vector2.ZERO, RADIUS, 0.0, TAU, 28, Color(0.45, 0.12, 0.12), 3.0)
	# Yeux méchants
	draw_circle(Vector2(-6, -3), 3.0, Color(1, 1, 1))
	draw_circle(Vector2(6, -3), 3.0, Color(1, 1, 1))
	draw_circle(Vector2(-6, -3), 1.4, Color(0.1, 0.05, 0.05))
	draw_circle(Vector2(6, -3), 1.4, Color(0.1, 0.05, 0.05))
