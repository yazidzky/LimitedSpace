extends Node

var xray_shader = preload("res://environment_xray.gdshader")

# Spatial Partitioning Grid
# Dictionary format: { Vector2i(grid_x, grid_z): [MeshInstance3D, ...] }
var grid: Dictionary = {} 
var grid_cell_size: float = 50.0 # Size of each grid cell in meters

var player: Node3D = null
"res://Map/map_3.tscn"

@export var visibility_radius: float = 30.0
@export var process_chunk_size: int = 50 # Reduced chunk size because we iterate fewer items now

var _last_player_grid_pos: Vector2i = Vector2i(9999, 9999) # Invalid start
var _active_meshes: Array = [] # List of meshes in current and neighbor cells

func _ready():
	print("--- OPTIMIZED SPATIAL GRID APPLIER STARTING ---")
	await get_tree().create_timer(0.05).timeout
	_start_gradual_apply()

func _start_gradual_apply():
	var parent = get_parent()
	if not parent: return
	
	print("Indexing started in: ", parent.name)
	await _collect_and_index_meshes(parent)
	print("Total grid cells created: ", grid.size())
	
	_run_spatial_visibility_loop()

# Public method to add new meshes after startup
func register_meshes(root_node: Node):
	await _collect_and_index_meshes(root_node)
	# Force update on next loop
	_last_player_grid_pos = Vector2i(9999, 9999) 

func _collect_and_index_meshes(root: Node):
	var stack = [root]
	var nodes_processed = 0
	
	while stack.size() > 0:
		var node = stack.pop_back()
		if node == null: continue
		
		if node.is_in_group("player") or node.name.to_lower().contains("player") or node.name.to_lower().contains("sophia"):
			continue
			
		if node is MeshInstance3D:
			# Apply shader immediately if needed
			if is_instance_valid(node) and node.get("material_overlay") == null:
				var xray_mat = ShaderMaterial.new()
				xray_mat.shader = xray_shader
				node.set("material_overlay", xray_mat)
			
			# Index into Grid
			_add_to_grid(node)
				
		for child in node.get_children():
			stack.push_back(child)
		
		nodes_processed += 1
		if nodes_processed % 200 == 0:
			await get_tree().process_frame

func _add_to_grid(mesh: MeshInstance3D):
	# Cache AABB for faster runtime access
	var local_aabb = mesh.get_aabb()
	mesh.set_meta("local_aabb", local_aabb)
	
	# Calculate global AABB to determine which cells it spans
	var global_aabb = mesh.global_transform * local_aabb
	
	var min_gx = int(floor(global_aabb.position.x / grid_cell_size))
	var max_gx = int(floor(global_aabb.end.x / grid_cell_size))
	var min_gz = int(floor(global_aabb.position.z / grid_cell_size))
	var max_gz = int(floor(global_aabb.end.z / grid_cell_size))
	
	# Add mesh to every cell it overlaps
	var cells_added = 0
	for gx in range(min_gx, max_gx + 1):
		for gz in range(min_gz, max_gz + 1):
			var key = Vector2i(gx, gz)
			if not grid.has(key):
				grid[key] = []
			grid[key].append(mesh)
			cells_added += 1
	
	if cells_added > 5:
		print("Large object indexed: ", mesh.name, " in ", cells_added, " cells.")

func _get_meshes_in_range(center_cell: Vector2i) -> Array:
	var result_set = {} # Use dictionary as a set for deduplication
	# Check center and 8 neighbors (3x3 grid)
	for x in range(-1, 2):
		for z in range(-1, 2):
			var key = center_cell + Vector2i(x, z)
			if grid.has(key):
				for mesh in grid[key]:
					result_set[mesh] = true # Add to set
	
	return result_set.keys()

func _run_spatial_visibility_loop():
	var hide_radius_sq = 45.0 * 45.0
	var collision_radius_sq = 25.0 * 25.0
	
	while true:
		if player == null:
			player = get_tree().get_first_node_in_group("player")
			await get_tree().create_timer(0.5).timeout
			continue
		
		var player_pos = player.global_position
		var pgx = floor(player_pos.x / grid_cell_size)
		var pgz = floor(player_pos.z / grid_cell_size)
		var current_grid_pos = Vector2i(pgx, pgz)
		
		# If changed grid cell, update active mesh list
		if current_grid_pos != _last_player_grid_pos:
			_active_meshes = _get_meshes_in_range(current_grid_pos)
			# print("Grid Cell Changed: ", current_grid_pos, " Active Meshes: ", _active_meshes.size())
			_last_player_grid_pos = current_grid_pos
		
		# Process active meshes in chunks to maintain FPS
		var current_idx = 0
		while current_idx < _active_meshes.size():
			var end = min(current_idx + process_chunk_size, _active_meshes.size())
			
			for i in range(current_idx, end):
				var mesh = _active_meshes[i]
				if not is_instance_valid(mesh): continue
				
				var local_aabb = mesh.get_meta("local_aabb", null)
				if local_aabb == null: continue
				
				# Fast distance check using AABB + Clamping
				var world_aabb = mesh.global_transform * local_aabb
				var closest_point = player_pos
				closest_point.x = clamp(closest_point.x, world_aabb.position.x, world_aabb.end.x)
				closest_point.y = clamp(closest_point.y, world_aabb.position.y, world_aabb.end.y)
				closest_point.z = clamp(closest_point.z, world_aabb.position.z, world_aabb.end.z)
				
				var dist_sq = player_pos.distance_squared_to(closest_point)
				
				# Update visibility
				mesh.visible = (dist_sq < hide_radius_sq)
				
				# Collision Generation
				if dist_sq < collision_radius_sq and not mesh.has_meta("has_collision"):
					mesh.create_trimesh_collision()
					mesh.set_meta("has_collision", true)
			
			current_idx = end
			await get_tree().process_frame
		
		await get_tree().create_timer(0.1).timeout # Scan 10 times a second
