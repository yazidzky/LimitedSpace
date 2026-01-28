extends Control

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	# Play Music
	var am = get_node_or_null("/root/AudioManager")
	if am and am.has_method("play_music_for_scene"):
		am.play_music_for_scene("start_screen")
	
	# Update Background
	var bg_node = get_node_or_null("Background")
	if bg_node and bg_node is TextureRect:
		var bg_tex = load("res://Previewlevel/background.png")
		if bg_tex:
			bg_node.texture = bg_tex
	
	# Style Buttons
	_style_button(%StartButton)
	_style_button(%CreditsButton)
	_style_button(%ExitButton)
	_style_button(%CloseCreditsButton)
	
	%StartButton.pressed.connect(_on_start_pressed)
	%CreditsButton.pressed.connect(_on_credits_pressed)
	%ExitButton.pressed.connect(_on_exit_pressed)
	%CloseCreditsButton.pressed.connect(_on_close_credits_pressed)

func _on_start_pressed():
	get_tree().change_scene_to_file("res://level_selection.tscn")


func _on_credits_pressed():
	%CreditsPanel.visible = true

func _on_close_credits_pressed():
	%CreditsPanel.visible = false

func _on_exit_pressed():
	get_tree().quit()

func _style_button(btn: Button):
	if not btn: return
	
	# Reference-inspired "Green Juicy" Style
	var base_green = Color("74c636") # Vibrant Green
	var dark_green = Color("4b8b22") # Darker Green/Shadow
	var light_green = Color("8be645") # Highlight Green
	
	# Normal Style
	var style_normal = StyleBoxFlat.new()
	style_normal.bg_color = base_green
	style_normal.corner_radius_top_left = 16
	style_normal.corner_radius_top_right = 16
	style_normal.corner_radius_bottom_right = 16
	style_normal.corner_radius_bottom_left = 16
	style_normal.border_width_bottom = 6
	style_normal.border_color = dark_green
	style_normal.shadow_size = 2
	style_normal.shadow_offset = Vector2(0, 2)
	
	# Hover Style
	var style_hover = style_normal.duplicate()
	style_hover.bg_color = light_green
	
	# Pressed Style
	var style_pressed = style_normal.duplicate()
	style_pressed.bg_color = base_green
	style_pressed.border_width_bottom = 2 # Compressed effect
	style_pressed.border_width_top = 4 # Shift down visual
	style_pressed.shadow_size = 0
	
	# Disabled Style
	var style_disabled = style_normal.duplicate()
	style_disabled.bg_color = Color("555555")
	style_disabled.border_color = Color("333333")
	
	btn.add_theme_stylebox_override("normal", style_normal)
	btn.add_theme_stylebox_override("hover", style_hover)
	btn.add_theme_stylebox_override("pressed", style_pressed)
	btn.add_theme_stylebox_override("disabled", style_disabled)
	btn.add_theme_stylebox_override("focus", style_normal) # No focus ring
	
	# Text styling
	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.add_theme_color_override("font_outline_color", Color("2a4d13"))
	btn.add_theme_constant_override("outline_size", 4)
	btn.add_theme_constant_override("font_size", 24)
