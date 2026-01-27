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
	
	# Try to find a good spawn point in Map 2
	var spawn_node = find_child("Cube", true, false)
	
	if spawn_node:
		print("Spawn point found at: ", spawn_node.global_position)
		player.global_position = spawn_node.global_position + Vector3.UP * 1.5
		player.rotation = Vector3.ZERO
	else:
		print("WARNING: No spawn node found. Using default position.")
		player.global_position = Vector3(0, 5, 0)
		
	# Teleportation Setup for Map 2
	_setup_teleport_system()

var player_ref: Node3D = null
var teleport_pairs: Array = [] # Array of dicts: { "trigger": Node3D, "target": Node3D, "cooldown": float }

func _setup_teleport_system():
	player_ref = get_tree().get_first_node_in_group("player")
	if not player_ref:
		player_ref = find_child("*layer*", true, false)
	
	# Define portals
	var portals_config = [
		{"from": "Cube_042", "to": "Cube", "two_way": false}, # Existing one
		{"from": "Cube_010", "to": "Cube_162", "two_way": true} # New one requested
	]
	
	print("--- TELEPORT CONFIGURATION START ---")
	# DEBUG: List all current children to find naming mismatches
	print("--- MAP 2 NODE HIERARCHY DEBUG ---")
	_print_all_children(self, 0)
	print("--- END HIERARCHY DEBUG ---")

	for config in portals_config:
		# Use wildcard to find either the MeshInstance or the StaticBody
		# User specifically mentioned StaticBody3D, so we try to find that or its parent
		var search_from = "*" + config["from"] + "*"
		var search_to = "*" + config["to"] + "*"
		
		var node_a = find_child(search_from, true, false)
		var node_b = find_child(search_to, true, false)
		
		if node_a and node_b:
			print("SUCCESS: Found pair %s and %s" % [node_a.name, node_b.name])
			_add_portal_pair(node_a, node_b)
			if config["two_way"]:
				_add_portal_pair(node_b, node_a)
		else:
			print("FAILURE: Teleport system: Skipping portal %s -> %s" % [config["from"], config["to"]])
			if not node_a: print(" - Could not find: ", search_from)
			if not node_b: print(" - Could not find: ", search_to)

func _print_all_children(node: Node, indent: int):
	var s = ""
	for i in range(indent): s += "  "
	print(s + node.name + " (" + node.get_class() + ")")
	for child in node.get_children():
		_print_all_children(child, indent + 1)

	print("Total teleport pairs active: ", teleport_pairs.size())
	print("--- TELEPORT CONFIGURATION END ---")

	if teleport_pairs.size() > 0:
		set_physics_process(true)
	else:
		set_physics_process(false)

func _add_portal_pair(trigger: Node3D, target: Node3D):
	print("Adding teleport portal: ", trigger.name, " -> ", target.name)
	teleport_pairs.append({
		"trigger": trigger,
		"target": target,
		"cooldown_timer": 0.0
	})
	
	# Visual Marker (Light) - ULTRAGLOW for "menyala" effect
	var marker = OmniLight3D.new()
	marker.light_color = Color.CYAN
	marker.light_energy = 10.0 # High energy for glow
	marker.omni_range = 8.0
	marker.shadow_enabled = true # Adds depth
	trigger.add_child(marker)
	
	# Visual Marker (Mesh) - Vibrant semi-transparent box
	var mesh_instance = MeshInstance3D.new()
	var box_mesh = BoxMesh.new()
	box_mesh.size = Vector3(1.8, 1.8, 1.8) # Slightly smaller than the cube to prevent z-fighting
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0, 1, 1, 0.4) 
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.emission_enabled = true
	material.emission = Color(0, 1, 1)
	material.emission_energy_multiplier = 4.0 # High emission
	box_mesh.material = material
	mesh_instance.mesh = box_mesh
	trigger.add_child(mesh_instance)
	
	# Register with visibility optimizer
	var applier = get_tree().get_first_node_in_group("environment_applier")
	if not applier:
		applier = get_tree().root.find_child("environment_xray_applier", true, false)
	
	if applier and applier.has_method("register_meshes"):
		applier.register_meshes(trigger)

func _physics_process(delta):
	if not player_ref: return
	
	for portal in teleport_pairs:
		if portal.cooldown_timer > 0:
			portal.cooldown_timer -= delta
			continue
			
		var dist = player_ref.global_position.distance_to(portal.trigger.global_position)
		if dist < 2.5:
			print("Teleporting player from ", portal.trigger.name, " to ", portal.target.name)
			
			# Vector3.UP * 2.5 ensures player lands ON TOP of the platform (pijakan)
			player_ref.global_position = portal.target.global_position + Vector3.UP * 2.5
			
			for p in teleport_pairs:
				if p.trigger == portal.target:
					p.cooldown_timer = 2.0
			break
