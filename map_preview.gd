extends SubViewportContainer

@onready var viewport = $SubViewport
@onready var camera = $SubViewport/Camera3D

func setup_preview(map_path: String, camera_pos: Vector3, camera_rot: Vector3):
	var map_scene = load(map_path)
	if map_scene:
		var instance = map_scene.instantiate()
		viewport.add_child(instance)
		
		# Position the camera relative to the map
		camera.position = camera_pos
		camera.rotation_degrees = camera_rot
		
		# Ensure the map is visible even if it's offset in its own scene
		# We might need to normalize its position if it's far from origin
		instance.position = Vector3.ZERO
