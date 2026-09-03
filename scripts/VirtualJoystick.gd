class_name VirtualJoystick
extends Node2D

## Joystick tactile flottant.
## Pose la base à l'endroit du premier appui, puis suit le doigt.
## `output` contient un vecteur normalisé (-1..1) lu par le jeu.
## Doit être placé sous un CanvasLayer pour rester fixe à l'écran.

var output := Vector2.ZERO

const MAX_RADIUS := 110.0
const DEAD_ZONE := 0.12
## Les appuis démarrant à droite de cette limite (coords de base, largeur 720)
## sont ignorés : cette zone est réservée au bouton d'attaque.
const MOVE_ZONE_MAX_X := 480.0

var _active := false
var _finger := -1
var _center := Vector2.ZERO
var _knob := Vector2.ZERO

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and not _active:
			if event.position.x > MOVE_ZONE_MAX_X:
				return   # zone réservée au bouton d'attaque
			_active = true
			_finger = event.index
			_center = event.position
			_knob = event.position
			output = Vector2.ZERO
			queue_redraw()
		elif not event.pressed and event.index == _finger:
			_reset()
	elif event is InputEventScreenDrag and _active and event.index == _finger:
		var off: Vector2 = event.position - _center
		if off.length() > MAX_RADIUS:
			off = off.normalized() * MAX_RADIUS
		_knob = _center + off
		var raw: Vector2 = off / MAX_RADIUS
		output = raw if raw.length() > DEAD_ZONE else Vector2.ZERO
		queue_redraw()

func _reset() -> void:
	_active = false
	_finger = -1
	output = Vector2.ZERO
	queue_redraw()

func _draw() -> void:
	if not _active:
		return
	draw_circle(_center, MAX_RADIUS, Color(1, 1, 1, 0.10))
	draw_arc(_center, MAX_RADIUS, 0.0, TAU, 48, Color(1, 1, 1, 0.35), 3.0)
	draw_circle(_knob, 42.0, Color(1, 1, 1, 0.30))
	draw_arc(_knob, 42.0, 0.0, TAU, 32, Color(1, 1, 1, 0.55), 3.0)
