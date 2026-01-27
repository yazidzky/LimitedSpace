extends Node3D

@export var target: Node3D

func _process(_delta):
	if target:
		global_position = target.global_position
