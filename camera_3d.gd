extends Camera3D

@export var player: Node3D
@export var hole_radius := 0.35
@export var hole_smoothness := 0.15

var faded_meshes: Dictionary = {} # MeshInstance3D -> {material: ShaderMaterial, original_transparency: Transparency}

func _ready():
	# Standard Dota 2 View Angle
	rotation_degrees = Vector3(-60, 0, 0)
	
	if player == null:
		player = get_tree().get_first_node_in_group("player")
		if player == null: player = owner
	
	print("--- CAMERA DOTA-VIEW SYSTEM ---")
	print("Active on: ", name)
	print("Targeting: ", str(player.name) if player else "UNKNOWN")
	
	# AUTO-SETUP X-RAY: Find any map node and apply the applier if not present
	_auto_setup_xray()
	print("-----------------------------")

func _auto_setup_xray():
	# Search for common map node names
	var map_names = ["MapTutorial", "map1", "map_1", "map2", "map_2", "map3", "map_3", "Map", "Environment", "Map1", "Map2", "Map3"]
	var map_node = null
	for mname in map_names:
		map_node = get_tree().root.find_child(mname, true, false)
		if map_node: break
	
	if map_node:
		var has_applier = false
		for child in map_node.get_children():
			if child.get_script() and child.get_script().resource_path.contains("environment_xray_applier"):
				has_applier = true
				child.add_to_group("environment_applier")
				break
		
		if not has_applier:
			print("Auto-applying X-Ray to: ", map_node.name)
			var applier = load("res://environment_xray_applier.gd").new()
			applier.name = "environment_xray_applier"
			map_node.add_child(applier)
			applier.add_to_group("environment_applier")

func _physics_process(_delta):
	if player == null: return

	var space_state = get_world_3d().direct_space_state
	var ray_origin = global_position
	var ray_target = player.global_position + Vector3.UP * 0.8
	
	var exclude = [self, player]
	if get_parent(): exclude.append(get_parent())
	
	var currently_hit_meshes: Array[MeshInstance3D] = []
	
	for i in range(5):
		var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_target)
		query.exclude = exclude
		var result = space_state.intersect_ray(query)
		
		if result:
			exclude.append(result.collider)
			var mesh = _find_mesh(result.collider)
			if mesh:
				if not currently_hit_meshes.has(mesh):
					currently_hit_meshes.append(mesh)
		else:
			break
			
	for mesh in currently_hit_meshes:
		if not faded_meshes.has(mesh):
			_enable_hole(mesh)
			
	var to_remove = []
	for mesh in faded_meshes:
		if not currently_hit_meshes.has(mesh):
			to_remove.append(mesh)
			
	for mesh in to_remove:
		_disable_hole(mesh)

func _process(_delta):
	if player == null: 
		player = get_tree().get_first_node_in_group("player")
		if player == null: return
	
	# ===== UPDATE GLOBAL SHADER PARAMS =====
	# 1. World Position
	RenderingServer.global_shader_parameter_set("player_world_pos", player.global_position)
	
	# 2. View Depth (Distance from camera plane)
	var cam_transform = global_transform.affine_inverse()
	var player_view_pos = cam_transform * player.global_position
	# In view space, -Z is forward. Distance to plane is -z.
	RenderingServer.global_shader_parameter_set("player_depth_view", -player_view_pos.z)
	
	# 3. Screen UV
	var screen_pos = unproject_position(player.global_position + Vector3.UP * 0.8)
	var viewport_size = get_viewport().get_visible_rect().size
	var screen_uv = (screen_pos / viewport_size).clamp(Vector2.ZERO, Vector2.ONE)
	RenderingServer.global_shader_parameter_set("player_screen_uv", screen_uv)
	
	# 4. X-Ray Toggle (Right-Click)
	var is_xray_pressed = Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)
	RenderingServer.global_shader_parameter_set("xray_enabled", is_xray_pressed)
	RenderingServer.global_shader_parameter_set("visibility_radius", 25.0) # Standard gameplay radius
	
	# Print to confirm tracking
	if Engine.get_frames_drawn() % 180 == 0:
		print("Camera Optimization: Visibility Mask Active (Sync: 25m)")
	
	# Update circle holes for the "Transparent Hole" feature
	for mesh in faded_meshes:
		var slot = faded_meshes[mesh]
		slot.material.set_shader_parameter("player_screen_pos", screen_uv)
		slot.material.set_shader_parameter("radius", hole_radius)
		slot.material.set_shader_parameter("smoothness", hole_smoothness)

func _enable_hole(mesh: MeshInstance3D):
	print("Enabling see-through on: ", mesh.name)
	var mat = ShaderMaterial.new()
	mat.shader = preload("res://transparency_circle.gdshader")
	faded_meshes[mesh] = {"material": mat}
	
	# CRITICAL: We use material_overlay but for it to "punch a hole", 
	# the shader itself must handle the transparency.
	# Actually, better yet, use material_overlay with ALPHA blend.
	mesh.material_overlay = mat

func _disable_hole(mesh: MeshInstance3D):
	if is_instance_valid(mesh):
		mesh.material_overlay = null
	faded_meshes.erase(mesh)

func _find_mesh(node: Node) -> MeshInstance3D:
	if node is MeshInstance3D: return node
	for child in node.get_children():
		var m = _find_mesh(child)
		if m: return m
	return null
