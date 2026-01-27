extends Node3D

var player_scene = preload("res://player_3d.tscn")
var teleport_trigger: Node3D = null
var teleport_target: Node3D = null
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
	
	# Wait a frame for everything to settle
	await get_tree().process_frame
	
	# 1. Setup Spawn and Portal Trigger
	teleport_trigger = find_child("Cylinder_003", true, false)
	if teleport_trigger:
		# Shift slightly to the side and higher to avoid collision sticking
		player.global_position = teleport_trigger.global_position + Vector3(2.0, 10.0, 2.0)
		player.rotation = Vector3.ZERO
		_create_marker(teleport_trigger, Color.CYAN, "Portal to Vantage Point")
	
	# 2. Setup Teleport Target and Rotation Trigger
	teleport_target = find_child("Cube_862", true, false)
	rotation_trigger = teleport_target # We use the same node for target and rotation trigger
	
	if teleport_target:
		_create_marker(teleport_target, Color.ORANGE, "Map Rotation Control")
		
	# Setup Level Transition Goal (Moving it to Cube_101)
	# 3. Setup Level Transition Goal Marker
	var goal_node = find_child("Cube_101", true, false)
	if goal_node:
		_create_marker(goal_node, Color.GREEN, "EXIT")

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
	
	# 1. Handle Teleportation (Portal)
	if teleport_trigger and teleport_target:
		var dist = player_ref.global_position.distance_to(teleport_trigger.global_position)
		if dist < 2.5:
			print("Entering Portal...")
			player_ref.global_position = teleport_target.global_position + Vector3.UP * 2.0
	
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
