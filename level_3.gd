extends Node3D

var player_scene = preload("res://player_3d.tscn")
var rotation_trigger: Node3D = null
var map_node: Node3D = null
var player_ref: Node3D = null

var is_rotating: bool = false
var target_rotation_y: float = 0.0

func _ready():
	# Use existing player if present, otherwise instance one
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		player = find_child("*layer*", true, false)
		
	if not player:
		print("No player found in scene, instantiating new one...")
		player = player_scene.instantiate()
		add_child(player)
	
	player_ref = player
	map_node = get_node("map3")

	# Setup Level Transition Goal IMMEDIATELY (Specific Coordinates from User)
	# User provided: X: 138.804, Y: -39.965, Z: -111.379
	var exit_pos = Vector3(138.804, -39.965, -111.379)
	var goal_marker_node = Marker3D.new()
	goal_marker_node.name = "Map3Goal"
	add_child(goal_marker_node)
	goal_marker_node.global_position = exit_pos
	
	_create_marker(goal_marker_node, Color.CYAN, "EXIT")
	print("Map 3 Exit Goal set IMMEDIATELY at: ", goal_marker_node.global_position)
	
	# Wait a frame for physics/rendering to settle
	await get_tree().process_frame
	
	# PORTAL REMOVED BY USER REQUEST
	# The cylinder barrier/portal is no longer active.
	
	# 2. Setup Rotation Trigger (Cube_862)
	# Previously was also the teleport target, now just a rotation trigger if reached
	rotation_trigger = find_child("Cube_862", true, false)
	
	if rotation_trigger:
		_create_marker(rotation_trigger, Color.ORANGE, "Map Rotation Control")
		

func _create_marker(parent: Node3D, color: Color, label: String):
	var marker = OmniLight3D.new()
	marker.light_color = color
	marker.light_energy = 10.0
	marker.omni_range = 10.0
	parent.add_child(marker)
	
	var mesh_instance = MeshInstance3D.new()
	var box_mesh = BoxMesh.new()
	box_mesh.size = Vector3(1.5, 3.0, 1.5)
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.albedo_color.a = 0.3
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 3.0
	box_mesh.material = mat
	mesh_instance.mesh = box_mesh
	parent.add_child(mesh_instance)
	print("Marker created for: ", label)
	
	# Register with visibility optimizer
	var applier = get_tree().get_first_node_in_group("environment_applier")
	if not applier:
		applier = get_tree().root.find_child("environment_xray_applier", true, false)
	
	if applier and applier.has_method("register_meshes"):
		applier.register_meshes(parent)

func _physics_process(delta):
	if not player_ref: return
	
	# 1. Portal Removed
	
	# 2. Handle Rotation Trigger
	if rotation_trigger and map_node:
		var dist = player_ref.global_position.distance_to(rotation_trigger.global_position)
		if dist < 2.5 and not is_rotating:
			print("Triggering Map Rotation!")
			is_rotating = true
			target_rotation_y = map_node.rotation.y + deg_to_rad(90.0)
	
	# 3. Smooth Rotation Animation
	if is_rotating:
		map_node.rotation.y = lerp_angle(map_node.rotation.y, target_rotation_y, delta * 2.0)
		if abs(angle_difference(map_node.rotation.y, target_rotation_y)) < 0.01:
			map_node.rotation.y = target_rotation_y
			is_rotating = false
			print("Rotation Complete.")
			
			
	# Note: level_transition.gd automatically handles Cube_101 as the goal in Map 3
