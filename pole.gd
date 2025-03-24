@tool
extends StaticBody3D
@export var move: bool
@export var center: float
@export var speed: float
@export var distance: float

var time: float

func _physics_process(delta: float) -> void:
	time += delta * speed
	
	if not move:
		position.y = center
		return

	position.y = center + sin(time) * distance
