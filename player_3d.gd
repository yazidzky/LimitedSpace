extends CharacterBody3D

@export var move_speed: float = 5.0
@export var rotate_speed: float = 3.0
@export var camera_follow_speed: float = 5.0
@export var camera_dist: float = 12.0
@export var camera_pitch: float = -60.0

@export var step_height: float = 1.5
@export var step_check_distance: float = 0.4

@onready var _camera: Camera3D = %Camera3D
@onready var _camera_pivot: Node3D = %CameraPivot
@onready var _skin: Node3D = %SophiaSkin

var _move_target_scene = preload("res://move_target.tscn")
var _selection_circle_scene = preload("res://selection_circle.tscn")

var _move_target_inst: Node3D
var _selection_circle_inst: Node3D

var target_position: Vector3
var has_target := false
var is_rotating := false

# Map 2/3 Gravity Shift Vars
var gravity_shift_enabled := false
var _target_up_dir := Vector3.UP
var _current_up_dir := Vector3.UP
var _target_z_tilt := 0.0
var _current_z_tilt := 0.0

# Smart Camera Occlusion Vars
var _occlusion_timer := 0.0

# Respawn System
var spawn_position := Vector3.ZERO
var spawn_rotation := Vector3.ZERO
var _spawn_update_timer := 0.0
var _spawn_locked := false  # Prevent spawn update during initial frames
var _current_camera_dist: float = 12.0 # Current dynamic zoom level
var _is_stabilizing := true
var _stabilize_timer := 0.6 # Seconds to freeze on spawn

# Sound Assets and State
var _step_sounds := [
	preload("res://player/sounds/robot_step_01.wav"),
	preload("res://player/sounds/robot_step_02.wav"),
	preload("res://player/sounds/robot_step_03.wav"),
	preload("res://player/sounds/robot_step_04.wav"),
	preload("res://player/sounds/robot_step_05.wav")
]
var _land_sound = preload("res://player/sounds/robot_land.wav")
var _step_audio_player: AudioStreamPlayer3D
var _land_audio_player: AudioStreamPlayer3D
var _step_timer := 0.0
@export var step_interval := 0.35
var _was_on_floor := true

func _ready():
	add_to_group("player") 
	print("--- PLAYER STARTUP: ", name, " ---")
	
	# Initialize Audio
	_step_audio_player = AudioStreamPlayer3D.new()
	add_child(_step_audio_player)
	_step_audio_player.bus = &"Master"
	_step_audio_player.max_distance = 20.0
	
	_land_audio_player = AudioStreamPlayer3D.new()
	add_child(_land_audio_player)
	_land_audio_player.bus = &"Master"
	_land_audio_player.max_distance = 20.0
	
	# Connect to scene change signal to update spawn when level changes
	get_tree().tree_changed.connect(_on_scene_changed)
	
	# Detect if we are in Map 2 or Map 3
	var scene_name = get_tree().current_scene.name.to_lower()
	gravity_shift_enabled = "level_3" in scene_name or "map3" in scene_name or "level_2" in scene_name or "map2" in scene_name
	
	if gravity_shift_enabled: 
		print("GRAVITY SHIFT ACTIVE: Level detected for dynamic traversal.")
		# Increase slope limit for tilted traversal
		floor_max_angle = deg_to_rad(80)
	
	# Dota-style camera setup: Fixed tilt
	_camera_pivot.top_level = true 
	_camera_pivot.rotation_degrees = Vector3(-60, 0, 0)
	
	# Reset child camera
	_camera.position = Vector3.ZERO
	_camera.rotation = Vector3.ZERO
	
	# Instantiate Markers
	_move_target_inst = _move_target_scene.instantiate()
	get_tree().root.add_child.call_deferred(_move_target_inst)
	_move_target_inst.visible = false
	
	_selection_circle_inst = _selection_circle_scene.instantiate()
	add_child(_selection_circle_inst)
	
	# Spawn Logic (Map 3 Requirement)
	# DISABLED: We use manual placement in level_3.tscn instead of searching for Cylinder_003
	# This fixes the issue where player spawns at unexpected locations
	
	# Snap camera pivot immediately to avoid flying from default position if needed
	var dist_h = camera_dist * cos(deg_to_rad(-camera_pitch))
	var height = camera_dist * sin(deg_to_rad(-camera_pitch))
	var camera_offset = Vector3(0, height, dist_h).rotated(Vector3.UP, rotation.y)
	_camera_pivot.global_position = global_position + camera_offset

	print("SPAWN: Player initialized at editor-placed position: ", global_position)
	
	# Wait a bit before saving spawn position to ensure player is stable
	await get_tree().create_timer(0.5).timeout
	_update_spawn_position()
	_current_camera_dist = camera_dist
	floor_snap_length = 1.5

func _on_scene_changed():
	# Reset spawn lock when scene changes
	_spawn_locked = false
	_spawn_update_timer = 0.0

func _update_spawn_position():
	# Save current position as new spawn point
	spawn_position = global_position
	spawn_rotation = rotation
	_spawn_locked = true
	print("Spawn position updated to: ", spawn_position)

func _respawn_player():
	# Reset player to spawn position
	global_position = spawn_position
	rotation = spawn_rotation
	velocity = Vector3.ZERO
	
	# Reset movement target
	has_target = false
	if _move_target_inst:
		_move_target_inst.visible = false
	
	# Reset gravity shift if enabled
	if gravity_shift_enabled:
		_target_up_dir = Vector3.UP
		_current_up_dir = Vector3.UP
		_target_z_tilt = 0.0
		_current_z_tilt = 0.0
		up_direction = Vector3.UP
	
	# Snap camera to correct position
	var dist_h = camera_dist * cos(deg_to_rad(-camera_pitch))
	var height = camera_dist * sin(deg_to_rad(-camera_pitch))
	var camera_offset = Vector3(0, height, dist_h).rotated(Vector3.UP, rotation.y)
	_camera_pivot.global_position = global_position + camera_offset
	
	print("Player respawned at: ", spawn_position)


func _apply_player_xray():
	var xray_shader = preload("res://player_xray.gdshader")
	var mesh_count = 0
	# Search all children recursively
	var stack = [self]
	while stack.size() > 0:
		var curr = stack.pop_back()
		if curr is MeshInstance3D:
			var mat = ShaderMaterial.new()
			mat.shader = xray_shader
			mat.render_priority = 10
			curr.material_overlay = mat
			mesh_count += 1
		for child in curr.get_children():
			stack.push_back(child)
			
	print("SUCCESS: Applied X-Ray shader to ", mesh_count, " player meshes.")


func _remove_player_xray():
	var stack = [self]
	while stack.size() > 0:
		var curr = stack.pop_back()
		if curr is MeshInstance3D:
			curr.material_overlay = null
		for child in curr.get_children():
			stack.push_back(child)

func _exit_tree() -> void:
	if _move_target_inst:
		_move_target_inst.queue_free()

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton and not event.is_echo()):
		return

	var mouse_event := event as InputEventMouseButton

	if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
		var mouse_pos = mouse_event.position
		var from = _camera.project_ray_origin(mouse_pos)
		var to = from + _camera.project_ray_normal(mouse_pos) * 5000 
		
		var space = get_world_3d().direct_space_state
		var query = PhysicsRayQueryParameters3D.create(from, to)
		query.exclude = [self]

		var result = space.intersect_ray(query)
		if result:
			target_position = result.position
			# GRAVITY SHIFT LOGIC
			if gravity_shift_enabled:
				var normal = result.normal
				var rel_hit_pos = result.position - global_position
				var height_offset = rel_hit_pos.dot(up_direction)
				
				# Only shift gravity if it's a tall wall (higher than step_height)
				if abs(normal.y) < 0.8 and height_offset > step_height: 
					_target_up_dir = normal
					_target_z_tilt = -atan2(normal.x, normal.y)
					print("GRAVITY SHIFT: New gravity established towards normal ", normal)
				else:
					if abs(normal.y) > 0.8:
						_target_up_dir = Vector3.UP
						_target_z_tilt = 0.0
					print("MOVEMENT/CLIMB: Surface is floor-like or low.")
		else:
			# Intersection with current tilted plane
			var plane = Plane(up_direction, global_position.dot(up_direction))
			var intersect = plane.intersects_ray(from, (to - from).normalized())
			if intersect:
				target_position = intersect

		has_target = true
		_move_target_inst.global_position = target_position + up_direction * 0.05
		
		# Robust orientation for MoveTarget (flush to surface or plane)
		var m_y = up_direction
		if result and "normal" in result: m_y = result.normal
		
		# Proyeksi ke plane
		var m_back_ref = Vector3.BACK.rotated(Vector3.UP, rotation.y)
		var m_z = m_back_ref - m_back_ref.project(m_y)
		if m_z.length() < 0.01: m_z = Vector3.FORWARD.rotated(Vector3.RIGHT, 0.1)
		m_z = m_z.normalized()
		var m_x = m_y.cross(m_z).normalized()
		m_z = m_x.cross(m_y).normalized()
		
		_move_target_inst.global_basis = Basis(m_x, m_y, m_z)
		_move_target_inst.visible = true

	elif mouse_event.button_index == MOUSE_BUTTON_RIGHT:
		if mouse_event.pressed:
			# Standard Camera Y-Rotation for ALL maps
			rotation.y = wrapf(rotation.y + deg_to_rad(30), -PI, PI)
			_apply_player_xray()
		else:
			_remove_player_xray()

func _physics_process(delta: float) -> void:
	# ===== STABILIZATION ON SPAWN =====
	if _is_stabilizing:
		velocity = Vector3.ZERO
		_stabilize_timer -= delta
		if _stabilize_timer <= 0:
			_is_stabilizing = false
			floor_snap_length = 2.0
			apply_floor_snap()
			print("Player stability achieved. Physics active.")
		return

	# ===== FALL DETECTION & RESPAWN =====
	# Respawns at the INITIAL level spawn point (set in _ready)
	# Increased threshold to allow for some verticality before reset
	# Map 3 is very vertical, so we need a much lower threshold (e.g. 150m below spawn)
	if gravity_shift_enabled:
		# GRAVITY SHIFT MODE: Use Distance Check
		# Player could fall in ANY direction (up, down, sideways) relative to world space
		if global_position.distance_to(spawn_position) > 300.0:
			print("RESPAWN: Player drifted too far into void! Resetting...")
			_respawn_player()
			return
	else:
		# STANDARD MODE: Use Y-Axis Check
		if global_position.y < (spawn_position.y - 50.0):
			print("RESPAWN: Player fell into void! Resetting...")
			_respawn_player()
			return

	# ===== AUTO-UPDATE SPAWN POSITION DISABLED =====
	# User Request: Always respawn at level start, never update spawn point during play.
	# Logic removed.

	# ===== GRAVITY SHIFT & PERSPECTIVE =====
	if gravity_shift_enabled:
		# Smoothly lerp perspective tilt and UP direction
		_current_z_tilt = lerp_angle(_current_z_tilt, _target_z_tilt, delta * 4.0)
		_current_up_dir = _current_up_dir.lerp(_target_up_dir, delta * 4.0).normalized()
		up_direction = _current_up_dir
	else:
		up_direction = Vector3.UP

	# Apply Gravity along local down
	if not is_on_floor():
		velocity -= up_direction * ProjectSettings.get_setting("physics/3d/default_gravity") * delta
	else:
		var vertical_vel = velocity.project(up_direction)
		velocity -= vertical_vel

	# ===== CAMERA FOLLOW =====
	# Gradually return to preferred distance if not forced by collision/occlusion
	_current_camera_dist = lerp(_current_camera_dist, camera_dist, delta * 2.0)
	
	var dist_h = _current_camera_dist * cos(deg_to_rad(-camera_pitch))
	var height = _current_camera_dist * sin(deg_to_rad(-camera_pitch))
	
	# Rotate camera around the CURRENT dynamic up direction
	# This keeps the "above" view consistent relative to her local orientation
	var orbit_axis = up_direction if gravity_shift_enabled else Vector3.UP
	var camera_offset = (orbit_axis * height) + (Vector3.BACK.rotated(orbit_axis, rotation.y) * dist_h)
	
	var ideal_cam_pos = global_position + camera_offset
	var final_cam_pos = ideal_cam_pos

	# --- CAMERA COLLISION (All Levels) ---
	var space_state = get_world_3d().direct_space_state
	# Cast from Sophia's chest/head outward to avoid starting inside she/floor
	var ray_origin = global_position + up_direction * 1.5 
	var query = PhysicsRayQueryParameters3D.create(ray_origin, ideal_cam_pos)
	query.exclude = [self]
	query.collision_mask = 1 # Environment collision
	
	var result = space_state.intersect_ray(query)
	var collision_lerp_speed = camera_follow_speed
	
	if result:
		# If obstructed, move camera closer to the hit point
		# Add a small buffer to avoid clipping into the wall
		var push_dir = (ray_origin - result.position).normalized()
		final_cam_pos = result.position + push_dir * 0.8
		# Use much faster lerp when moving TOWARDS the player (clipping)
		collision_lerp_speed = 30.0 
	
	# Transition smoothly to the final position
	_camera_pivot.global_position = _camera_pivot.global_position.lerp(
		final_cam_pos,
		collision_lerp_speed * delta
	)
	
	# 2. Apply Camera Orientation
	# Simply look at Sophia's head and apply the Z-tilt for the Map 3 puzzle
	var look_target = global_position + (up_direction * 1.5)
	_camera_pivot.look_at(look_target, up_direction)
	
	if gravity_shift_enabled and abs(_current_z_tilt) > 0.01:
		# Apply Z-tilt roll relative to the camera's view
		_camera_pivot.rotate_object_local(Vector3.BACK, _current_z_tilt)

	# ===== SMART CAMERA OCCLUSION =====
	# Cast ray from camera to player head to check if view is blocked
	# (space_state already declared above)
	var cam_pos = _camera.global_position
	var head_pos = global_position + up_direction * 1.5
	var occlusion_query = PhysicsRayQueryParameters3D.create(cam_pos, head_pos)
	# Exclude things that are NOT environment (player, markers, etc)
	occlusion_query.exclude = [self, _move_target_inst, _selection_circle_inst]
	
	var occ_result = space_state.intersect_ray(occlusion_query)
	if occ_result and occ_result.collider != self:
		# View is blocked by environment
		_occlusion_timer += delta
		
		# Proactively zoom in if view is blocked
		if _occlusion_timer > 0.2:
			_current_camera_dist = lerp(_current_camera_dist, camera_dist * 0.4, delta * 5.0)
			
		if _occlusion_timer > 1.2:
			# Auto-rotate 30 degrees to try and find a clear view
			rotation.y = wrapf(rotation.y + deg_to_rad(30), -PI, PI)
			_occlusion_timer = 0.0 # Reset to allow smooth transition
			print("Smart Camera: Occlusion detected, auto-rotating view.")
	else:
		# View is clear, gradually reset timer
		_occlusion_timer = max(0.0, _occlusion_timer - delta * 2.0)
	
	# ===== MOVEMENT =====
	if has_target:
		# Calculate direction on the local floor plane
		var diff = target_position - global_position
		# Remove component along up_direction to keep it on plane
		var dir = diff - diff.project(up_direction)

		if dir.length() > 0.1:
			dir = dir.normalized()
			# Apply velocity relative to the plane
			var horizontal_vel = dir * move_speed
			velocity = velocity.project(up_direction) + horizontal_vel

			# Handle skin rotation (must stay upright relative to dynamic UP)
			var s_v_y = up_direction
			var s_v_z = dir.normalized()
			var s_v_x = s_v_y.cross(s_v_z).normalized()
			s_v_z = s_v_x.cross(s_v_y).normalized()
			
			# Face direction of movement
			var target_basis = Basis(s_v_x, s_v_y, s_v_z)
			_skin.global_basis = _skin.global_basis.slerp(target_basis, delta * 15.0)
		else:
			has_target = false
			_move_target_inst.visible = false
			velocity -= velocity - velocity.project(up_direction) # Zero out horizontal
	else:
		# Friction/Braking relative to plane
		var horizontal_vel = velocity - velocity.project(up_direction)
		velocity -= horizontal_vel * 0.2
		
		# IDLE Orientation: Face current camera direction but stay upright
		var v_y = up_direction
		var cam_back = Vector3.BACK.rotated(Vector3.UP, rotation.y)
		
		# Proyeksi cam_back ke plane yang tegak lurus v_y
		var v_z = cam_back - cam_back.project(v_y)
		if v_z.length() < 0.01:
			v_z = Vector3.FORWARD.rotated(Vector3.RIGHT, 0.1) # Fallback safe vector
		v_z = v_z.normalized()
		
		var v_x = v_y.cross(v_z).normalized()
		v_z = v_x.cross(v_y).normalized()
		
		# Sophia faces v_z. The PI rotation is to align the specific model's forward
		var target_basis = Basis(v_x, v_y, v_z)
		_skin.global_basis = _skin.global_basis.slerp(target_basis, delta * 10.0)

	# ===== FINAL UPDATES =====
	# 1. Selection Circle: Robust orientation flush to plane
	_selection_circle_inst.global_position = global_position + up_direction * 0.05
	var c_y = up_direction
	var c_back_ref = Vector3.BACK.rotated(Vector3.UP, rotation.y)
	var c_z = c_back_ref - c_back_ref.project(c_y)
	if c_z.length() < 0.01: c_z = Vector3.FORWARD.rotated(Vector3.RIGHT, 0.1)
	c_z = c_z.normalized()
	var c_x = c_y.cross(c_z).normalized()
	c_z = c_x.cross(c_y).normalized()
	_selection_circle_inst.global_basis = Basis(c_x, c_y, c_z)

	# Apply Physics
	var was_on_floor = is_on_floor()
	move_and_slide()
	
	if is_on_wall() and was_on_floor:
		_perform_step_up(delta)
	
	# Animasi
	var ground_vel = velocity - velocity.project(up_direction)
	if ground_vel.length() > 0.1:
		_skin.move()
		# Step Sound Logic
		if is_on_floor():
			_step_timer += delta
			if _step_timer >= step_interval:
				_play_random_step()
				_step_timer = 0.0
	else:
		_skin.idle()
		_step_timer = step_interval # Reset timer so it plays immediately when starting to move

	# Landing Sound Logic
	if is_on_floor() and not _was_on_floor:
		_play_land_sound()
	_was_on_floor = is_on_floor()

func _play_random_step():
	if _step_sounds.is_empty(): return
	var sound = _step_sounds.pick_random()
	_step_audio_player.stream = sound
	_step_audio_player.pitch_scale = randf_range(0.9, 1.1)
	_step_audio_player.play()

func _play_land_sound():
	if not _land_sound: return
	_land_audio_player.stream = _land_sound
	_land_audio_player.pitch_scale = 1.0
	_land_audio_player.play()

func _perform_step_up(_delta):
	# DYNAMIC STEP UP: Uses current gravity up_direction

	var step_dist = 0.4
	
	# Get movement direction relative to the current plane
	var move_dir = (velocity - velocity.project(up_direction)).normalized()
	if move_dir.length() < 0.1: return
	
	# 1. Test moving "UP" relative to current gravity
	var up_step = up_direction * step_height
	if !test_move(global_transform, up_step):
		# 2. If can move up, test moving "FORWARD" relative to plane
		var forward_step = move_dir * step_dist
		var up_transform = global_transform.translated(up_step)
		if !test_move(up_transform, forward_step):
			# 3. If clear, teleport onto the step
			global_position += up_step + (forward_step * 0.5)
			# Re-align with floor
			await get_tree().physics_frame
			apply_floor_snap()
