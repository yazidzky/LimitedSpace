extends Control

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	# Close any leftover dialogue
	if has_node("/root/DialogueSystem"):
		get_node("/root/DialogueSystem").close_dialogue()
	
	# Play Music
	var am = get_node_or_null("/root/AudioManager")
	if am and am.has_method("play_music_for_scene"):
		am.play_music_for_scene("start_screen")
	
	# Update Background
	var bg_node = get_node_or_null("Background")
	if bg_node and bg_node is TextureRect:
		var bg_tex = load("res://ui/background.png")
		if bg_tex:
			bg_node.texture = bg_tex
	
	# Style Buttons
	_style_button(%StartButton)
	_style_button(%CreditsButton)
	_style_button(%ExitButton)
	_style_button(%CloseCreditsButton)
	
	%StartButton.pressed.connect(_on_start_pressed)
	
	# Connect Tutorial Button if it exists (added dynamically or via scene update)
	var tut_btn = get_node_or_null("%TutorialButton")
	if tut_btn:
		_style_button(tut_btn)
		tut_btn.pressed.connect(_on_tutorial_pressed)
		
	%CreditsButton.pressed.connect(_on_credits_pressed)
	%ExitButton.pressed.connect(_on_exit_pressed)
	%CloseCreditsButton.pressed.connect(_on_close_credits_pressed)

func _on_start_pressed():
	if has_node("/root/LoadingManager"):
		get_node("/root/LoadingManager").load_level("res://sectionlevel/level_selection.tscn")
	else:
		get_tree().change_scene_to_file("res://sectionlevel/level_selection.tscn")

func _on_tutorial_pressed():
	var gm = get_node_or_null("/root/GameManager")
	if gm: gm.was_accessed_from_tutorial_button = true
	
	if has_node("/root/LoadingManager"):
		get_node("/root/LoadingManager").load_level("res://Tutorial.tscn")
	else:
		get_tree().change_scene_to_file("res://Tutorial.tscn")

func _on_credits_pressed():
	%CreditsPanel.visible = true

func _on_close_credits_pressed():
	%CreditsPanel.visible = false

func _on_exit_pressed():
	get_tree().quit()

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
	style_normal.modulate_color = Color.WHITE # Keep natural asset color
	
	# Hover Style
	var style_hover = style_normal.duplicate()
	style_hover.modulate_color = Color(0.9, 1.0, 0.9, 1.0) # Subtle green highlight
	
	# Pressed Style
	var style_pressed = style_normal.duplicate()
	style_pressed.modulate_color = Color(0.7, 0.7, 0.7, 1.0) # Darken on press
	
	btn.add_theme_stylebox_override("normal", style_normal)
	btn.add_theme_stylebox_override("hover", style_hover)
	btn.add_theme_stylebox_override("pressed", style_pressed)
	btn.add_theme_stylebox_override("focus", style_normal)
	
	# Text styling (fallback)
	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.add_theme_color_override("font_outline_color", Color.BLACK)
	btn.add_theme_constant_override("outline_size", 8)
	btn.add_theme_font_size_override("font_size", 32)
