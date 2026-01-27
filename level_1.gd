extends Node3D

var player_scene = preload("res://player_3d.tscn")

func _ready():
	# Use existing player if present, otherwise instance one
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		player = find_child("*layer*", true, false)
		
	if not player:
		print("No player found in scene, instantiating new one...")
		player = player_scene.instantiate()
		add_child(player)
	else:
		print("Existing player found: ", player.name)
	
	# Wait a frame for everything to settle
	await get_tree().process_frame
	
	# Find Cube20 to use as spawn position
	# Use find_child with recursive search to find it inside map1 (GLB)
	var spawn_node = find_child("*ube20*", true, false)
	
	if spawn_node:
		print("Spawn point Cube20 found at: ", spawn_node.global_position)
		player.global_position = spawn_node.global_position + Vector3.UP * 1.5
		# Ensure player faces a good direction
		player.rotation = Vector3.ZERO
	else:
		print("WARNING: Spawn node Cube20 not found. Using default position.")
		player.global_position = Vector3(0, 5, 0)
