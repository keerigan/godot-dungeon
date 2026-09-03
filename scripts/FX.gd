class_name FX
extends RefCounted

## Petits utilitaires visuels générés par code (aucun asset binaire).

## Texture radiale blanche (centre opaque -> bords transparents) pour les
## lumières 2D (PointLight2D).
static func make_light_texture(size: int = 256) -> GradientTexture2D:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.6, 1.0])
	g.colors = PackedColorArray([
		Color(1, 1, 1, 1),
		Color(1, 1, 1, 0.5),
		Color(1, 1, 1, 0.0),
	])
	var t := GradientTexture2D.new()
	t.gradient = g
	t.width = size
	t.height = size
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(1.0, 0.5)
	return t
