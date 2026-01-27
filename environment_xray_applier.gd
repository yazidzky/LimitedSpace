extends Node

var xray_shader = preload("res://environment_xray.gdshader")
var all_meshes: Array[MeshInstance3D] = []
var player: Node3D = null

@export var visibility_radius: float = 30.0
@export var process_chunk_size: int = 200 # Significant increase: scanning is fast, physics is slow

var _last_player_check_pos: Vector3 = Vector3(999,999,999) # Start far away to force first pass

func _ready():
	print("--- FIXING CLIPPING: ULTRA-FAST SCAN APPLIER STARTING ---")
	await get_tree().create_timer(0.05).timeout
	_start_gradual_apply()

func _start_gradual_apply():
	var parent = get_parent()
	if not parent: return
	
	print("Indexing started in: ", parent.name)
	await _collect_meshes_non_blocking(parent)
	print("Total meshes indexed: ", all_meshes.size())
	
	# Start BOTH simultaneously to be as fast as possible on spawn
	_apply_shaders_gradually()
	_run_visibility_loop()

# Public method to add new meshes after startup (for markers etc)
func register_meshes(root_node: Node):
	await _collect_meshes_non_blocking(root_node)
	# Re-apply shaders to newly found meshes
	_apply_shaders_gradually()

func _collect_meshes_non_blocking(root: Node):
	var stack = [root]
	var nodes_processed = 0
	
	while stack.size() > 0:
		var node = stack.pop_back()
		if node == null: continue
		
		if node.is_in_group("player") or node.name.to_lower().contains("player") or node.name.to_lower().contains("sophia"):
			continue
			
		if node is MeshInstance3D and not all_meshes.has(node):
			node.set_meta("local_aabb", node.get_aabb())
			all_meshes.append(node)
				
		for child in node.get_children():
			stack.push_back(child)
		
		nodes_processed += 1
		if nodes_processed % 200 == 0:
			await get_tree().process_frame

func _apply_shaders_gradually():
	var batch_size = 30
	for i in range(all_meshes.size()):
		var mesh = all_meshes[i]
		if is_instance_valid(mesh) and mesh.get("material_overlay") == null:
			var xray_mat = ShaderMaterial.new()
			xray_mat.shader = xray_shader
			mesh.set("material_overlay", xray_mat)
		
		if i % batch_size == 0:
			await get_tree().process_frame

func _run_visibility_loop():
	var hide_radius_sq = 45.0 * 45.0
	var collision_radius_sq = 25.0 * 25.0
	var is_first_run = true
	
	while true:
		if player == null:
			player = get_tree().get_first_node_in_group("player")
		
		if player:
			var player_pos = player.global_position
			
			# Movement Check
			var dist_jumped_sq = player_pos.distance_squared_to(_last_player_check_pos)
			
			# TELEPORT DETECTION: If player jumped > 5m, we need PRIORITY collisions
			if dist_jumped_sq > 25.0:
				print("COLLISION SECURITY: Teleport detected, running priority scan...")
				_priority_collision_scan(player_pos)
				# Reset state but don't skip the normal loop
				_last_player_check_pos = player_pos
			
			if not is_first_run and dist_jumped_sq < 0.1:
				await get_tree().create_timer(0.2).timeout
				continue
			
			_last_player_check_pos = player_pos
			var current_index = 0
			
			while current_index < all_meshes.size():
				var end = min(current_index + process_chunk_size, all_meshes.size())
				for i in range(current_index, end):
					var mesh = all_meshes[i]
					if not is_instance_valid(mesh): continue
					
					var local_aabb = mesh.get_meta("local_aabb", null)
					if local_aabb == null: continue
					
					var world_aabb = mesh.global_transform * local_aabb
					var closest_point = player_pos
					closest_point.x = clamp(closest_point.x, world_aabb.position.x, world_aabb.end.x)
					closest_point.y = clamp(closest_point.y, world_aabb.position.y, world_aabb.end.y)
					closest_point.z = clamp(closest_point.z, world_aabb.position.z, world_aabb.end.z)
					
					var dist_sq = player_pos.distance_squared_to(closest_point)
					
					# Update visibility
					mesh.visible = (dist_sq < hide_radius_sq)
					
					# Throttled Collision (Normal Flow)
					if dist_sq < collision_radius_sq and not mesh.has_meta("has_collision"):
						mesh.create_trimesh_collision()
						mesh.set_meta("has_collision", true)
						if not is_first_run or dist_sq > 4.0:
							await get_tree().process_frame
				
				current_index = end
				await get_tree().process_frame
			
			is_first_run = false
		
		await get_tree().create_timer(0.1).timeout

# New security function to prevent clipping after jumps
func _priority_collision_scan(pos: Vector3):
	var security_radius_sq = 15.0 * 15.0 # Check everything in 15m instantly
	var collision_count = 0
	for mesh in all_meshes:
		if not is_instance_valid(mesh): continue
		if mesh.has_meta("has_collision"): continue
		
		if mesh.global_position.distance_squared_to(pos) < security_radius_sq:
			mesh.create_trimesh_collision()
			mesh.set_meta("has_collision", true)
			collision_count += 1
	if collision_count > 0:
		print("COLLISION SECURITY: Priority created ", collision_count, " collisions near arrival point.")
