extends Node

@export var next_level: String = "res://level_1.tscn"
@export var trigger_distance: float = 4.0

var target_node: Node3D = null
var player: Node3D = null
var has_key := false

var _hud: CanvasLayer = null
var _player_marker: Control = null
var _dist_value: Label = null
var _total_dist_label: Label = null
var _bar: ColorRect = null
var _initial_dist: float = 0.0
var _key_container: HBoxContainer = null
var _key_icons: Array[ColorRect] = []
var _required_keys: Array[Node] = []
var _exit_portal_node: Node3D = null
var _collected_keys_count := 0

# Pause Menu Refs
var _pause_menu: Control = null
var _resume_btn: Button = null
var _restart_btn: Button = null
var _menu_btn: Button = null
var _guide_arrow: Node3D = null
var tutorial_guide_active: bool = false

# Victory Menu Refs
var _victory_menu: Control = null
var _victory_next_btn: Button = null
var _victory_menu_btn: Button = null
var _percentage_label: Label = null

func _ready():
	print("--- LEVEL TRANSITION STARTUP ---")
	await get_tree().process_frame
	_update_level_info()
	
	# Tutorial Overlay Injection
	var current_scene = get_tree().current_scene
	if current_scene and "tutorial" in current_scene.name.to_lower():
		var tut_overlay = load("res://tutorial_overlay.tscn").instantiate()
		add_child(tut_overlay)

func _update_level_info():
	var current_scene = get_tree().current_scene
	if not current_scene: return
	
	var scene_name = current_scene.name.to_lower()
	print("Current Scene Name: ", scene_name)
	
	# Level Progression Logic
	if ("level" in scene_name and "2" in scene_name) or ("map" in scene_name and "2" in scene_name):
		next_level = "res://Map/level_3.tscn"
	elif ("level" in scene_name and "3" in scene_name) or ("map" in scene_name and "3" in scene_name):
		next_level = "res://start_screen.tscn"
	elif ("tutorial" in scene_name):
		next_level = "res://level_1.tscn"
	elif ("level" in scene_name and "1" in scene_name) or ("map" in scene_name and "1" in scene_name) or scene_name == "level_1" or scene_name == "map1":
		next_level = "res://level_2.tscn"
		
	# Find Player
	player = get_tree().get_first_node_in_group("player")
	if not player: player = get_parent().find_child("*layer*", true, false)
	
	# Find Exit Portal
	_exit_portal_node = _find_tower_node(get_tree().current_scene)
	
	# Find Keys
	_required_keys.clear()
	var keys = get_tree().get_nodes_in_group("key")
	for key in keys:
		_required_keys.append(key)
		if not key.is_connected("collected", _on_key_collected):
			key.collected.connect(_on_key_collected)
	
	_collected_keys_count = 0
	
	if _required_keys.size() > 0:
		has_key = false
		_update_current_target()
	else:
		has_key = true # Auto-unlock if no key exists
		target_node = _exit_portal_node
	
	if target_node:
		print("SUCCESS: Objective target set to ", target_node.name)
		if not _hud: _setup_hud()
		_calculate_initial_dist()
	else:
		print("CRITICAL ERROR: No transition target found!")

func _update_current_target():
	if has_key:
		target_node = _exit_portal_node
		return

	# Find nearest uncollected key
	var nearest_key = null
	var min_dist = INF
	
	for key in _required_keys:
		if is_instance_valid(key) and key.visible:
			var d = player.global_position.distance_to(key.global_position)
			if d < min_dist:
				min_dist = d
				nearest_key = key
	
	if nearest_key:
		target_node = nearest_key
	else:
		target_node = _exit_portal_node

func _on_key_collected():
	_collected_keys_count += 1
	print("OBJECTIVE UPDATE: Key collected! (", _collected_keys_count, "/", _required_keys.size(), ")")
	
	if _collected_keys_count <= _key_icons.size():
		var icon = _key_icons[_collected_keys_count - 1]
		if is_instance_valid(icon):
			icon.color = Color(1, 0.9, 0.2) # Bright yellow/gold
	
	# PLAY KEY DIALOGUE
	var scene_name = get_tree().current_scene.name.to_lower()
	var key_dialogue = "key_pickup" # Default
	if "tutorial" in scene_name: key_dialogue = "key_pickup_tutorial"
	elif "level" in scene_name and "1" in scene_name: key_dialogue = "key_pickup_level_1"
	elif "level" in scene_name and "2" in scene_name: key_dialogue = "key_pickup_level_2"
	elif "level" in scene_name and "3" in scene_name: key_dialogue = "key_pickup_level_3"
	
	if has_node("/root/DialogueSystem"):
		get_node("/root/DialogueSystem").start_dialogue(key_dialogue)
	
	if _collected_keys_count >= _required_keys.size():
		has_key = true
		print("OBJECTIVE COMPLETE: All keys collected! Exit unlocked.")
		_apply_portal_effects()
	
	# CHECKPOINT: Update player spawn position to current position
	if player and player.has_method("_update_spawn_position"):
		player._update_spawn_position()
		print("CHECKPOINT: Player spawn point updated to current location.")
	
	_update_current_target()
	_calculate_initial_dist() # Refresh progress bar for next stage


func _setup_hud():
	var hud_scene = preload("res://hud.tscn")
	if not hud_scene: return
	_hud = hud_scene.instantiate()
	add_child(_hud)
	_player_marker = _hud.get_node("%PlayerMarker")
	_dist_value = _hud.get_node("%DistanceValue")
	_total_dist_label = _hud.get_node("%TotalDistance")
	_bar = _hud.get_node("%Bar")
	_percentage_label = _hud.get_node("%PercentageLabel")
	_key_container = _hud.get_node("%KeyContainer")
	
	# Create dynamic key icons
	_key_icons.clear()
	if _key_container:
		# Clear existing children (placeholders)
		for child in _key_container.get_children():
			child.queue_free()
		
		# Wait a frame for children to be removed
		await get_tree().process_frame
		
		# Add new icons based on key count
		for i in range(_required_keys.size()):
			var icon_rect = ColorRect.new()
			icon_rect.custom_minimum_size = Vector2(20, 20)
			icon_rect.color = Color(0.2, 0.2, 0.2, 0.8) # Dark grey initially
			
			icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
			
			# Add a subtle border or something to make it look like a key slot
			var border = ReferenceRect.new()
			border.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			border.border_color = Color.BLACK
			border.border_width = 2.0
			border.editor_only = false
			icon_rect.add_child(border)
			
			_key_container.add_child(icon_rect)
			_key_icons.append(icon_rect)
			
			# If already collected (e.g. level reload)
			if i < _collected_keys_count:
				icon_rect.color = Color(1, 0.9, 0.2)
	
	# Initial Key Visual State
	if _key_container:
		_key_container.modulate = Color.WHITE if _required_keys.size() > 0 else Color.TRANSPARENT
	
	# Pause Menu Setup
	_pause_menu = _hud.get_node("%PauseMenu")
	_resume_btn = _hud.get_node("%ResumeButton")
	_restart_btn = _hud.get_node("%RestartButton")
	_menu_btn = _hud.get_node("%MainMenuButton")
	
	var pause_btn = _hud.get_node("%PauseButton")
	
	# Apply Styles
	_style_button(_resume_btn)
	_style_button(_restart_btn)
	_style_button(_menu_btn)
	_style_button(pause_btn)
	
	if pause_btn: pause_btn.pressed.connect(_on_pause_pressed)
	if _resume_btn: _resume_btn.pressed.connect(_on_resume_pressed)
	if _restart_btn: _restart_btn.pressed.connect(_on_restart_pressed)
	if _menu_btn: _menu_btn.pressed.connect(_on_main_menu_pressed)
	
	# Victory Menu Setup
	_victory_menu = _hud.get_node("%VictoryMenu")
	_victory_next_btn = _hud.get_node("%NextLevelButton")
	_victory_menu_btn = _hud.get_node("%MenuButtonVictory")
	
	_style_button(_victory_next_btn)
	_style_button(_victory_menu_btn)
	
	if _victory_next_btn: _victory_next_btn.pressed.connect(_on_next_level_pressed)
	if _victory_menu_btn: _victory_menu_btn.pressed.connect(_on_main_menu_pressed)

func _style_button(btn: Button):
	if not btn: return
	
	var box_tex = load("res://ui/buttonbox.svg")
	
	# Normal Style
	var style_normal = StyleBoxTexture.new()
	style_normal.texture = box_tex
	style_normal.texture_margin_left = 12
	style_normal.texture_margin_top = 12
	style_normal.texture_margin_right = 12
	style_normal.texture_margin_bottom = 12
	style_normal.modulate_color = Color(1, 1, 1, 0.9) # Light semi-trans
	
	# Hover Style
	var style_hover = style_normal.duplicate()
	style_hover.modulate_color = Color(0.8, 1, 0.8, 1) # Greenish hover
	
	# Pressed Style
	var style_pressed = style_normal.duplicate()
	style_pressed.modulate_color = Color(0.6, 0.7, 0.6, 1)
	
	btn.add_theme_stylebox_override("normal", style_normal)
	btn.add_theme_stylebox_override("hover", style_hover)
	btn.add_theme_stylebox_override("pressed", style_pressed)
	btn.add_theme_stylebox_override("focus", style_normal)
	
	# Text styling (for fallback text)
	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.add_theme_color_override("font_outline_color", Color.BLACK)
	btn.add_theme_constant_override("outline_size", 6)
	btn.add_theme_constant_override("font_size", 28)

func _on_pause_pressed(): 
	# Don't allow pausing if victory menu is already shown
	if _victory_menu and _victory_menu.visible: return
	_toggle_pause(true)
func _on_resume_pressed(): _toggle_pause(false)
func _on_restart_pressed():
	_toggle_pause(false)
	if player and player.has_method("_respawn_player"): player._respawn_player()
	else: get_tree().reload_current_scene()

func _on_main_menu_pressed():
	_toggle_pause(false)
	if not is_inside_tree(): return
	
	if has_node("/root/LoadingManager"): get_node("/root/LoadingManager").load_level("res://start_screen.tscn")
	elif get_tree(): get_tree().change_scene_to_file("res://start_screen.tscn")

func _toggle_pause(should_pause: bool):
	get_tree().paused = should_pause
	if _pause_menu: _pause_menu.visible = should_pause
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	# Hide Dialogue System when Paused to prevent overlap
	if has_node("/root/DialogueSystem"):
		var ds = get_node("/root/DialogueSystem")
		if ds.visible and should_pause:
			ds.visible = false
			# We'll store its state to show it back on resume if needed
			_pause_menu.set_meta("was_dialogue_visible", true)
		elif not should_pause and _pause_menu.has_meta("was_dialogue_visible"):
			ds.visible = true
			_pause_menu.remove_meta("was_dialogue_visible")
	
	# Hide Tutorial Overlay when Paused
	var tut_overlay = get_node_or_null("TutorialOverlay")
	if tut_overlay:
		tut_overlay.visible = not should_pause

func _calculate_initial_dist():
	if player and target_node:
		_initial_dist = player.global_position.distance_to(target_node.global_position)
		if _total_dist_label: _total_dist_label.text = "%dm" % int(_initial_dist)

func _find_tower_node(root: Node):
	if not root: return null
	
	var current_scene = root.get_tree().current_scene
	var scene_name = ""
	if current_scene: scene_name = current_scene.name.to_lower()
	
	# 1. Map Specific Logic
	if "tutorial" in scene_name:
		var t1 = root.find_child("Cube_046", true, false)
		if t1: return t1
	
	if ("level" in scene_name and "3" in scene_name) or ("map" in scene_name and "3" in scene_name):
		var t3_goal = root.find_child("Map3Goal", true, false)
		if t3_goal: return t3_goal
		var t3_cube = root.find_child("Cube_101", true, false)
		if t3_cube: return t3_cube

	if ("level" in scene_name and "2" in scene_name) or ("map" in scene_name and "2" in scene_name):
		var t2_goal = root.find_child("Cube_400", true, false)
		if t2_goal: return t2_goal
		var t2_portal = root.find_child("Cube_042", true, false)
		if t2_portal: return t2_portal
		
	if ("level" in scene_name and "1" in scene_name) or ("map" in scene_name and "1" in scene_name) or scene_name == "level_1" or scene_name == "map1":
		var t_map1 = root.find_child("Cube_042", true, false)
		if t_map1: return t_map1

	# 2. General Fallbacks
	var names = ["Cube_046", "Cube_042", "Tower", "Goal"]
	for n in names:
		var t = root.find_child("*" + n + "*", true, false)
		if t and t is Node3D:
			return t

	return null

func _apply_portal_effects():
	if not _exit_portal_node: return
	
	print("PORTAL: Applying glow effects to ", _exit_portal_node.name)
	
	# Add a bright light to the portal
	var portal_light = _exit_portal_node.find_child("PortalGlow", true, false)
	if not portal_light:
		portal_light = OmniLight3D.new()
		portal_light.name = "PortalGlow"
		_exit_portal_node.add_child(portal_light)
	
	portal_light.light_color = Color(1, 0.8, 0.2) # Golden
	portal_light.light_energy = 15.0
	portal_light.omni_range = 10.0
	
	# Try to find mesh to apply emission
	var stack = [_exit_portal_node]
	while stack.size() > 0:
		var node = stack.pop_back()
		if node is MeshInstance3D:
			for i in range(node.get_surface_override_material_count()):
				var mat = node.get_surface_override_material(i)
				if mat is StandardMaterial3D:
					mat.emission_enabled = true
					mat.emission = Color(1, 0.8, 0.2)
					mat.emission_energy_multiplier = 2.0
		stack.append_array(node.get_children())

func _physics_process(_delta):
	if _required_keys.size() > 0 and not has_key:
		_update_current_target()

	if not target_node:
		_update_level_info()
		return
		
	if not player: 
		player = get_tree().get_first_node_in_group("player")
		return
	
	# 1. Handle Objective UI & HUD
	var dist_to_target = player.global_position.distance_to(target_node.global_position)
	_update_ui(dist_to_target)
	
	# 3D GUIDE ARROW Logic
	if not is_instance_valid(_guide_arrow):
		var arrow_scene = load("res://guide_arrow.tscn")
		if arrow_scene:
			_guide_arrow = arrow_scene.instantiate()
			player.add_child(_guide_arrow)
			_guide_arrow.top_level = true # Independent transform
	
	if is_instance_valid(_guide_arrow) and is_instance_valid(target_node):
		# Follow player
		_guide_arrow.global_position = player.global_position + Vector3(0, 2.5, 0)
		# Point to target
		_guide_arrow.look_at(target_node.global_position, Vector3.UP)
		_guide_arrow.rotation.x = 0 
		
		# Visibility Logic: Show only if has_key OR is tutorial (and tutorial active)
		var is_tutorial = "tutorial" in get_tree().current_scene.name.to_lower()
		_guide_arrow.visible = (is_tutorial and tutorial_guide_active) or has_key
		
	elif is_instance_valid(_guide_arrow):
		_guide_arrow.visible = false
	
	# 2. Robust Backup Pickup
	if not has_key and target_node.is_in_group("key"):
		if dist_to_target < 1.5:
			if target_node.has_method("_collect"):
				target_node._collect()
	
	# 3. Check for EXIT GOAL
	if _exit_portal_node:
		var dist_to_exit = player.global_position.distance_to(_exit_portal_node.global_position)
		if dist_to_exit < trigger_distance:
			if has_key:
				_change_level()
			else:
				if _dist_value and _dist_value.text != "NEED KEY!":
					var old_text = _dist_value.text
					_dist_value.text = "NEED KEY!"
					_dist_value.modulate = Color.RED
					await get_tree().create_timer(1.5).timeout
					if is_instance_valid(_dist_value):
						_dist_value.modulate = Color.WHITE
						_dist_value.text = old_text

func _update_ui(current_dist: float):
	if not _hud: return
	
	if _dist_value:
		var prefix = "KEY: " if not has_key and _required_keys.size() > 0 else "GOAL: "
		_dist_value.text = prefix + "%dm" % int(current_dist)
	
	if _initial_dist > 0:
		var progress = 1.0 - clamp(current_dist / _initial_dist, 0.0, 1.0)
		var bar_width = 564.0 # Matches the inner space of the SVG
		if _player_marker: _player_marker.position.x = 18.0 + (progress * bar_width) - (_player_marker.size.x / 2.0)
		if _bar: _bar.size.x = progress * bar_width
		if _percentage_label:
			_percentage_label.text = "%d%%" % int(progress * 100)
		
		# Update Game Manager Progress
		var gm = get_node_or_null("/root/GameManager")
		if gm and gm.has_method("update_level_progress"):
			var scene_path = get_tree().current_scene.scene_file_path
			gm.update_level_progress(scene_path, int(progress * 100))



var _loading_in_progress = false

func _change_level():
	if _loading_in_progress: return
	_loading_in_progress = true # Prevent multiple triggers
	
	# Stop gameplay immediately
	set_physics_process(false)
	if player and player is PhysicsBody3D:
		player.set_physics_process(false)
		player.velocity = Vector3.ZERO
	
	# PLAY ENDING DIALOGUE
	var scene_name = get_tree().current_scene.name.to_lower()
	var end_dialogue = ""
	if "tutorial" in scene_name: end_dialogue = "tutorial_end"
	elif ("level" in scene_name and "1" in scene_name) or ("map" in scene_name and "1" in scene_name): end_dialogue = "level_1_end"
	elif ("level" in scene_name and "2" in scene_name) or ("map" in scene_name and "2" in scene_name): end_dialogue = "level_2_end"
	elif ("level" in scene_name and "3" in scene_name) or ("map" in scene_name and "3" in scene_name): end_dialogue = "level_3_end"
	
	if end_dialogue != "" and has_node("/root/DialogueSystem"):
		var ds = get_node("/root/DialogueSystem")
		ds.start_dialogue(end_dialogue)
		await ds.dialogue_finished
		
		if not is_inside_tree(): return
		
		# If it's the last level, play the overall game ending dialogue
		if end_dialogue == "level_3_end":
			ds.start_dialogue("game_ending")
			await ds.dialogue_finished
			if not is_inside_tree(): return
	
	# Instead of changing immediately, show Victory Screen
	if _victory_menu:
		# Close Pause Menu if it was open
		if _pause_menu:
			_pause_menu.visible = false
			get_tree().paused = false
		
		# Hide the Pause Button itself during Victory
		var pause_btn = _hud.get_node_or_null("%PauseButton")
		if pause_btn: pause_btn.visible = false
		
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		_victory_menu.visible = true
		
		# HIDE CONTINUE BUTTON IF ACCESSED FROM START SCREEN TUTORIAL BUTTON
		var gm = get_node_or_null("/root/GameManager")
		if gm and gm.was_accessed_from_tutorial_button and "tutorial" in scene_name:
			if _victory_next_btn: _victory_next_btn.visible = false
			print("CONTINUE HIDDEN: Tutorial accessed from Start Screen.")
		
		# Save Progress Immediately on Victory
		if gm and gm.has_method("complete_level"):
			gm.complete_level(get_tree().current_scene.scene_file_path)
	else:
		# Fallback if no HUD
		_on_next_level_pressed()

func _on_next_level_pressed():
	if not is_inside_tree(): return
	
	if next_level == "" or next_level == "res://start_screen.tscn":
		# If no next level is defined, go back to menu
		_on_main_menu_pressed()
		return

	if has_node("/root/LoadingManager"):
		get_node("/root/LoadingManager").load_level(next_level)
	elif get_tree():
		get_tree().change_scene_to_file(next_level)
