extends Node

@export var next_level: String = "res://level_1.tscn"
@export var trigger_distance: float = 1.0

var target_node: Node3D = null
var player: Node3D = null
var _hud: CanvasLayer = null
var _dist_label: Label = null

func _ready():
	print("--- LEVEL TRANSITION STARTUP ---")
	await get_tree().process_frame # Wait for scene to settle
	_update_level_info()

func _update_level_info():
	# Determine Next Level based on Current Level
	var current_scene = get_tree().current_scene
	if not current_scene: return
	
	var scene_name = current_scene.name.to_lower()
	print("Current Scene Name: ", scene_name)
	
	if ("level" in scene_name and "2" in scene_name) or ("map" in scene_name and "2" in scene_name):
		next_level = "res://Map/level_3.tscn"
		print("Detected Map 2: Next level set to ", next_level)
		
	elif ("level" in scene_name and "3" in scene_name) or ("map" in scene_name and "3" in scene_name):
		next_level = "res://Tutorial.tscn"
		print("Detected Map 3: Next level set to ", next_level)
		
	# Fallback/Default for Map 1
	elif ("level" in scene_name and "1" in scene_name) or ("map" in scene_name and "1" in scene_name) or scene_name == "level_1" or scene_name == "map1":
		next_level = "res://level_2.tscn"
		print("Detected Map 1: Next level set to ", next_level)
		
	# Find Player
	player = get_tree().get_first_node_in_group("player")
	if not player: player = get_parent().find_child("*layer*", true, false)
	
	# Find Tower
	target_node = _find_tower_node(get_tree().root)
	
	if target_node:
		print("SUCCESS: Locked onto Tower at ", target_node.global_position)
		_create_debug_marker()
		_setup_hud()
	else:
		print("CRITICAL ERROR: No transition target (Tower/Goal/Cube_042/Cube_046) found!")

func _setup_hud():
	var hud_scene = preload("res://hud.tscn")
	_hud = hud_scene.instantiate()
	add_child(_hud)
	_dist_label = _hud.get_node("%DistanceLabel")

func _find_tower_node(root: Node) -> Node3D:
	var current_scene = root.get_tree().current_scene
	var scene_name = ""
	if current_scene:
		scene_name = current_scene.name.to_lower()
	
	print("Searching target for scene: ", scene_name)

	# Context-Aware Search
	if "tutorial" in scene_name:
		var t1 = root.find_child("Cube_046", true, false)
		if t1: return t1
	
	# Map 3 Logic (Cube_101) - Check this BEFORE Map 2/1 to avoid partial matches on "level"
	if ("level" in scene_name and "3" in scene_name) or ("map" in scene_name and "3" in scene_name):
		var t3 = root.find_child("Cube_101", true, false)
		if t3: return t3

	# Map 2 Logic (Cube_400 or Cube_042)
	if ("level" in scene_name and "2" in scene_name) or ("map" in scene_name and "2" in scene_name):
		var t2_goal = root.find_child("Cube_400", true, false)
		if t2_goal: return t2_goal
		
		# Fallback to old name if needed
		var t2_portal = root.find_child("Cube_042", true, false)
		if t2_portal: return t2_portal
		
	# Map 1 Logic (Cube_042)
	# Strict check to ensure we don't pick this up in Map 2
	if ("level" in scene_name and "1" in scene_name) or ("map" in scene_name and "1" in scene_name) or scene_name == "level_1" or scene_name == "map1":
		var t_map1 = root.find_child("Cube_042", true, false)
		if t_map1: return t_map1

	# Fallback: Check both if Scene Name didn't match specific logic
	# Priority to Cube_046 if we are unsure, but try 042 first if it looks like a normal level
	var t_fallback_1 = root.find_child("Cube_046", true, false)
	var t_fallback_2 = root.find_child("Cube_042", true, false)
	
	if t_fallback_1 and "tutorial" in t_fallback_1.get_parent().name.to_lower(): return t_fallback_1
	if t_fallback_2: return t_fallback_2
	if t_fallback_1: return t_fallback_1
	
	# Last Resort: Generic Names
	var t3 = root.find_child("*Tower*", true, false) 
	if t3: return t3
	
	var t4 = root.find_child("*Goal*", true, false)
	if t4: return t4

	return null

func _create_debug_marker():
	# Create a visible light at the tower to show the goal
	var light = OmniLight3D.new()
	light.light_color = Color.GOLD
	light.light_energy = 5.0
	light.omni_range = 10.0
	target_node.add_child(light)
	print("Debug marker (Gold Light) created at Tower.")
		
func _physics_process(_delta):
	# Periodically check if scene changed (hacky but works if signals aren't set up)
	# Better: Call _update_level_info() when entering tree or via signal. 
	# For now, we'll rely on _change_level calling it or checking dynamically.
	
	if not target_node or not player: 
		return
	
	var dist = player.global_position.distance_to(target_node.global_position)
	
	if _dist_label:
		_dist_label.text = "Distance: %.1f m" % dist
	
	# Check distance
	if dist < 4.0: 
		print("PLAYER REACHED TOWER! Distance: ", dist)
		_change_level()

func _input(event):
	# DEBUG: Press 'L' to force level change
	if event is InputEventKey and event.pressed and event.keycode == KEY_L:
		print("Forcing level change via 'L' key.")
		_update_level_info() # Ensure info is up to date
		_change_level()

var _loading_in_progress = false
var _loading_next_scene = ""

func _change_level():
	if _loading_in_progress: return
	
	# Stop script from running multiple times
	set_physics_process(false)
	print("Starting Threaded Load for: ", next_level)
	
	_loading_next_scene = next_level
	_loading_in_progress = true
	
	# Show loading UI
	if _dist_label:
		_dist_label.text = "Loading Next Level..."
	
	# Request background load
	var err = ResourceLoader.load_threaded_request(_loading_next_scene)
	if err != OK:
		print("THREADED LOAD REQUEST FAILED: ", err)
		_loading_in_progress = false
		set_physics_process(true)
		return
	
	# Switch to process polling
	set_process(true)

func _process(_delta):
	if not _loading_in_progress: return
	
	var progress = []
	var status = ResourceLoader.load_threaded_get_status(_loading_next_scene, progress)
	
	if _dist_label:
		var p_val = 0
		if progress.size() > 0: p_val = int(progress[0] * 100)
		_dist_label.text = "Loading: %d%%" % p_val
	
	match status:
		ResourceLoader.THREAD_LOAD_LOADED:
			print("Scene Loaded! Switching...")
			var packed_scene = ResourceLoader.load_threaded_get(_loading_next_scene)
			get_tree().change_scene_to_packed(packed_scene)
			_loading_in_progress = false
			set_process(false)
		ResourceLoader.THREAD_LOAD_FAILED:
			print("THREAD LOAD FAILED")
			_loading_in_progress = false
			set_process(false)
		ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			print("THREAD LOAD INVALID")
			_loading_in_progress = false
			set_process(false)
