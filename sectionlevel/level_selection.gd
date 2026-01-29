extends Node3D

var _loading_in_progress = false

# Map node names to level paths, label text, and glow colors
var level_map = {
	"circle_002": {
		"file": "res://Tutorial.tscn", 
		"label": "Squire's Path (Tutorial)",
		"offset": Vector3(0, 4, 0),
		"color": Color.WHITE,
		"image": "res://Previewlevel/Squire's_path.png",
		"story_key": "tutorial_enter"
	},
	"circle_003": {
		"file": "res://level_1.tscn", 
		"label": "Coiled Citadel (Adventure)",
		"offset": Vector3(0, 4, 0),
		"color": Color.GREEN,
		"image": "res://Previewlevel/Coiled_Citadel.png",
		"story_key": "level_1_enter"
	},
	"circle_005": {
		"file": "res://level_2.tscn", 
		"label": "Azure Depths (Aquatic)",
		"offset": Vector3(0, 4, 0),
		"color": Color.CYAN,
		"image": "res://Previewlevel/Azure_Depths.png",
		"story_key": "level_2_enter"
	},
	"circle_006": {
		"file": "res://Map/level_3.tscn", 
		"label": "Cranium Gardens (Mysterious)",
		"offset": Vector3(0, 4, 0),
		"color": Color.MAGENTA,
		"image": "res://Previewlevel/Cranium_Gardens.png",
		"story_key": "level_3_enter"
	},
	"circle_004": {
		"file": "res://Map/level_3.tscn", 
		"label": "Cranium Gardens (Mysterious)",
		"offset": Vector3(0, 4, 0),
		"color": Color.MAGENTA,
		"image": "res://Previewlevel/Cranium_Gardens.png",
		"story_key": "level_3_enter"
	}
}

@onready var player_scene = preload("res://player_3d.tscn")
@onready var level_section_mesh = $levelsection

# Track if intro played to avoid loop if returning to scene (basic check)
static var intro_played_once = false 

func _ready():
	print("--- LEVEL SELECTION READY ---")
	# Enable mouse
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	_setup_lighting()
	
	# Delay slightly to ensure tree is built
	await get_tree().process_frame
	
	_setup_interaction_zones()
	_spawn_player()
	_setup_ui()
	
	# Adjust camera of the newly spawned player
	var player = get_node_or_null("Player 3D")
	if player:
		# Use script variables for robust camera control
		player.camera_dist = 110.0 # Much higher to see the whole map
		player.camera_pitch = -80.0 # More top-down view
	
	# TRIGGER SEQUENTIAL INTRO STORY EVERY TIME
	var intro_keys = ["intro", "intro_2", "intro_3", "intro_4"]
	var gm = get_node_or_null("/root/GameManager")
	var key = "intro"
	
	if gm:
		key = intro_keys[gm.current_intro_index]
		gm.current_intro_index = (gm.current_intro_index + 1) % intro_keys.size()
		
		# OVERRIDE: If all maps are completed, show the special greeting
		if gm.level_best_progress.get("res://Map/level_3.tscn", 0) == 100:
			key = "game_completed_greeting"
	
	_play_story(key)

func _play_story(key: String):
	if has_node("/root/DialogueSystem"):
		get_node("/root/DialogueSystem").start_dialogue(key)

func _setup_lighting():
	# Ensure there is light
	if find_children("*", "DirectionalLight3D").size() == 0:
		var light = DirectionalLight3D.new()
		light.light_energy = 1.5
		light.rotation_degrees = Vector3(-50, 30, 0)
		light.shadow_enabled = true
		add_child(light)

func _spawn_player():
	var spawn_pos = Vector3(0, 50, 0) # Default fallback
	
	# 1. Try "Spawn" node
	var internal_spawn = _find_node_by_name_pattern(level_section_mesh, "Spawn")
	
	if internal_spawn:
		spawn_pos = internal_spawn.global_position + Vector3(0, 15.0, 0)
	else:
		# 2. Try near Tutorial Circle
		var fallback = _find_node_by_name_pattern(level_section_mesh, "circle_002")
		if fallback:
			spawn_pos = fallback.global_position + Vector3(5, 10, 0)
	
	if not has_node("Player 3D"):
		var p = player_scene.instantiate()
		p.name = "Player 3D"
		add_child(p)
		p.global_position = spawn_pos
		
		# SCALE FIX
		var skin = p.get_node_or_null("%SophiaSkin")
		if skin: skin.scale = Vector3(3, 3, 3)
		
		# Scale Physics via Resource
		var col_node = p.get_node_or_null("CollisionShape3D")
		if col_node and col_node.shape:
			var new_shape = col_node.shape.duplicate()
			if new_shape is CapsuleShape3D:
				new_shape.radius *= 3.0
				new_shape.height *= 3.0
			col_node.shape = new_shape
		
		p.move_speed = 15.0
		p.velocity = Vector3.ZERO

func _setup_ui():
	var canvas = CanvasLayer.new()
	add_child(canvas)
	var btn = Button.new()
	btn.text = "Exit to Main Menu"
	btn.position = Vector2(20, 20)
	btn.size = Vector2(280, 80) # Larger for premium asset
	_style_button(btn)
	btn.pressed.connect(func():
		if has_node("/root/DialogueSystem"):
			get_node("/root/DialogueSystem").close_dialogue()
		get_tree().change_scene_to_file("res://start_screen.tscn")
	)
	canvas.add_child(btn)

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
	style_normal.modulate_color = Color(1, 1, 1, 0.9)
	
	# Hover Style
	var style_hover = style_normal.duplicate()
	style_hover.modulate_color = Color(0.8, 1.0, 0.8, 1.0)
	
	# Pressed Style
	var style_pressed = style_normal.duplicate()
	style_pressed.modulate_color = Color(0.6, 0.6, 0.6, 1.0)
	
	btn.add_theme_stylebox_override("normal", style_normal)
	btn.add_theme_stylebox_override("hover", style_hover)
	btn.add_theme_stylebox_override("pressed", style_pressed)
	btn.add_theme_stylebox_override("focus", style_normal)
	
	# Text styling
	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.add_theme_color_override("font_outline_color", Color.BLACK)
	btn.add_theme_constant_override("outline_size", 6)
	btn.add_theme_constant_override("font_size", 24)

func _setup_interaction_zones():
	if not level_section_mesh: return
	
	for node_name in level_map.keys():
		var target_node = _find_node_by_name_pattern(level_section_mesh, node_name)
		if target_node:
			_create_interaction(target_node, level_map[node_name])
		else:
			print("MISSING NODE: " + node_name)

func _create_interaction(mesh_node: Node, data: Dictionary):
	# 1. Create Area
	var area = Area3D.new()
	area.name = "Trigger_" + mesh_node.name
	add_child(area)
	# Moves the area slightly UP to ensure it catches the player's body center, 
	# and ensures it isn't buried in the floor.
	area.global_position = mesh_node.global_position + Vector3(0, 1.0, 0)
	
	# 2. Collision Shape (Cylinder) - MADE HUGE to ensure detection even if standing nearby
	var col = CollisionShape3D.new()
	var shape = CylinderShape3D.new()
	shape.radius = 8.0 # Huge radius (was 4.0) to catch player standing near the button
	shape.height = 8.0
	col.shape = shape
	area.add_child(col)
	
	# 3. GLOWING VISUALS
	var mesh_inst = MeshInstance3D.new()
	var torus = TorusMesh.new()
	torus.inner_radius = 7.5
	torus.outer_radius = 8.0
	mesh_inst.mesh = torus
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = data["color"]
	mat.emission_enabled = true
	mat.emission = data["color"]
	mat.emission_energy_multiplier = 2.0
	mesh_inst.material_override = mat
	area.add_child(mesh_inst)
	
	# Light shaft
	var shaft = MeshInstance3D.new()
	var cyl = CylinderMesh.new()
	cyl.top_radius = 7.5
	cyl.bottom_radius = 7.5
	cyl.height = 10.0
	shaft.mesh = cyl
	
	var mat_shaft = StandardMaterial3D.new()
	mat_shaft.albedo_color = data["color"]
	mat_shaft.albedo_color.a = 0.1
	mat_shaft.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat_shaft.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat_shaft.emission_enabled = true
	mat_shaft.emission = data["color"]
	mat_shaft.emission_energy_multiplier = 0.5
	shaft.material_override = mat_shaft
	shaft.position.y = 5.0
	area.add_child(shaft)
	
	# 4. CARD DISPLAY (Sprite3D)
	if data.has("image"):
		var sprite = Sprite3D.new()
		sprite.texture = load(data["image"])
		sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		sprite.pixel_size = 0.05 # Adjust scale (smaller = bigger image in world)
		sprite.position = Vector3(0, 12, 0) # Float high above circle
		area.add_child(sprite)
	
	# 5. Label
	var label = Label3D.new()
	label.text = data["label"]
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.font_size = 300 # HUGE TEXT requested
	label.outline_size = 32
	label.position = Vector3(0, 20, 0) # Above the card
	area.add_child(label)

	# 6. Logic
	area.collision_mask = 0b1111 # Scan layers 1-4
	area.monitorable = true
	area.monitoring = true
	area.body_entered.connect(_on_level_area_entered.bind(data)) # Bind full data
	print("Zone Created: " + data["label"] + " Radius: 8.0")

func _on_level_area_entered(body, data):
	if _loading_in_progress: return
	
	print("HIT ZONE PROBE: ", body.name, " Type: ", body.get_class())
	# Accept ANY CharacterBody3D or Player group
	if body is CharacterBody3D or body.is_in_group("player") or "Player" in body.name:
		_loading_in_progress = true
		print(">>> VALID PLAYER DETECTED! Playing Story then Loading: ", data["file"])
		
		# Stop Player
		if body is CharacterBody3D:
			body.velocity = Vector3.ZERO
			body.set_physics_process(false) 
		
		# Play Story
		if has_node("/root/DialogueSystem") and data.has("story_key"):
			var ds = get_node("/root/DialogueSystem")
			ds.start_dialogue(data["story_key"])
			await ds.dialogue_finished
		
		# Resume & Load
		call_deferred("_load_level", data["file"])

func _load_level(path):
	if not is_inside_tree():
		_loading_in_progress = false
		return
		
	var gm = get_node_or_null("/root/GameManager")
	if gm and "tutorial" in path.to_lower():
		gm.was_accessed_from_tutorial_button = false
		
	if has_node("/root/LoadingManager"):
		get_node("/root/LoadingManager").load_level(path)
	elif get_tree():
		get_tree().change_scene_to_file(path)
	else:
		_loading_in_progress = false

func _find_node_by_name_pattern(root: Node, pattern: String) -> Node:
	if root.name.to_lower().contains(pattern.to_lower()):
		return root
	for child in root.get_children():
		var res = _find_node_by_name_pattern(child, pattern)
		if res: return res
	return null
