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
	
	# Find SpawnPoint first
	var spawn_node = find_child("SpawnPoint", true, false)
	
	if not spawn_node:
		# Fallback to scanning for Cube20 if SpawnPoint is missing
		spawn_node = find_child("*ube20*", true, false)
	
	if spawn_node:
		print("Spawn point found: ", spawn_node.name, " at ", spawn_node.global_position)
		player.global_position = spawn_node.global_position
		# Use marker rotation if available
		player.rotation = spawn_node.rotation
	else:
		print("WARNING: No valid spawn point found. Using default position.")
		player.global_position = Vector3(0, 5, 0)
