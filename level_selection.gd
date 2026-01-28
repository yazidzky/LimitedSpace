extends Control

@onready var scroll_container = %ScrollContainer
@onready var h_box = %HBoxContainer

var current_index = 0
var card_width = 400 # Width of each level card + separation

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	# Play Music
	var am = get_node_or_null("/root/AudioManager")
	if am and am.has_method("play_music_for_scene"):
		am.play_music_for_scene("level_selection")
	
	# Update Background
	var bg_node = get_node_or_null("Background")
	if bg_node and bg_node is TextureRect:
		var bg_tex = load("res://Previewlevel/background.png")
		if bg_tex:
			bg_node.texture = bg_tex
	
	# FIX: Tutorial Card Hierarchy Issue
	_fix_tutorial_card_hierarchy()
	
	_update_cards()
	_snap_to_current()
	
	# Style Navigation Buttons
	_style_button(%NextButton)
	_style_button(%PrevButton)
	_style_button(%BackButton)
	
	%NextButton.pressed.connect(_on_next_pressed)
	%PrevButton.pressed.connect(_on_prev_pressed)
	%BackButton.pressed.connect(_on_back_pressed)
	
	# Apply "Cartoon Bold" look to Title
	var title = get_node_or_null("Title")
	if title:
		title.add_theme_constant_override("outline_size", 16)
		title.add_theme_color_override("font_outline_color", Color.BLACK)

func _fix_tutorial_card_hierarchy():
	# The Tutorial Card in scene has PreviewContainer inside Label. We need to move it up.
	var tutorial_card = h_box.get_node_or_null("TutorialCard")
	if tutorial_card:
		var label = tutorial_card.get_node_or_null("Label")
		if label:
			var preview = label.get_node_or_null("PreviewContainer")
			if preview:
				label.remove_child(preview)
				tutorial_card.add_child(preview)
				# Move it above the play button but below Label visually if needed, 
				# but z-order depends on tree order. Add child puts it at end (on top).
				# We want it behind the Play Button usually? 
				# Actually PlayButton is at end.
				tutorial_card.move_child(preview, 0) # Put at bottom?
				# Wait, PlayButton and LockIcon are on top.
				# Let's put PreviewContainer just after BG
				var bg = tutorial_card.get_node_or_null("BG")
				if bg:
					var bg_idx = bg.get_index()
					tutorial_card.move_child(preview, bg_idx + 1)

func _update_cards():
	var cards = h_box.get_children()
	# Updated preview images as requested
	var preview_images = [
		"res://Previewlevel/Squire's_path.png",
		"res://Previewlevel/Coiled_Citadel.png",
		"res://Previewlevel/Azure_Depths.png",
		"res://Previewlevel/Cranium_Gardens.png"
	]
	
	for i in range(cards.size()):
		var card = cards[i]
		
		# Force uniform size as requested
		card.custom_minimum_size = Vector2(360, 360)
		card.size = Vector2(360, 360)
		
		# Enable mouse interaction for the card container
		card.mouse_filter = Control.MOUSE_FILTER_PASS
		if not card.mouse_entered.is_connected(_on_card_hover):
			card.mouse_entered.connect(_on_card_hover.bind(card))
		if not card.mouse_exited.is_connected(_on_card_exit):
			card.mouse_exited.connect(_on_card_exit.bind(card))
			
		# Hide default background to let image shine
		var d_bg = card.get_node_or_null("BG")
		if d_bg: d_bg.visible = false

		var lock = card.get_node_or_null("LockIcon")
		var play_btn = card.get_node_or_null("PlayButton")
		
# Setup 2D Preview (FULL CARD)
		var preview_container = card.get_node_or_null("PreviewContainer")
		if preview_container and i < preview_images.size():
			# Force Container to fill the card
			preview_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			
			# Clear previous preview if any
			for child in preview_container.get_children():
				child.queue_free()
			
			# Create a Mask Panel for Rounded Corners
			var mask_panel = Panel.new()
			mask_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			mask_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
			
			# Define Rounded Style
			var style_box = StyleBoxFlat.new()
			style_box.corner_radius_top_left = 30
			style_box.corner_radius_top_right = 30
			style_box.corner_radius_bottom_right = 30
			style_box.corner_radius_bottom_left = 30
			style_box.bg_color = Color(1, 1, 1, 1) # Opaque for mask
			# Add a subtle shadow/border to the card shape
			style_box.border_width_left = 6
			style_box.border_width_top = 6
			style_box.border_width_right = 6
			style_box.border_width_bottom = 6
			style_box.border_color = Color(0.8, 0.5, 0.3, 1) # Cardboard-ish border
			style_box.shadow_size = 4
			style_box.shadow_offset = Vector2(0, 4)
			
			mask_panel.add_theme_stylebox_override("panel", style_box)
			
			# Enable Clipping
			# 1 = CLIP_CHILDREN_ONLY (Godot 4.0+)
			mask_panel.clip_children = 1 
			
			preview_container.add_child(mask_panel)
				
			var texture_rect = TextureRect.new()
			# Safety check for loading image
			if ResourceLoader.exists(preview_images[i]):
				texture_rect.texture = load(preview_images[i])
			else:
				push_warning("Image not found: " + preview_images[i])
				
			texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED # Full cover
			texture_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			mask_panel.add_child(texture_rect)
			
			# Add a dim overlay for text readability if needed, or gradient at bottom
			var gradient = TextureRect.new()
			# Simple vertical gradient (transparent to black)
			var grad_tex = GradientTexture2D.new()
			grad_tex.fill_to = Vector2(0, 1)
			grad_tex.fill_from = Vector2(0, 0.5)
			grad_tex.gradient = Gradient.new()
			grad_tex.gradient.colors = PackedColorArray([Color(0,0,0,0), Color(0,0,0,0.8)])
			gradient.texture = grad_tex
			gradient.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			gradient.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			mask_panel.add_child(gradient)
		
		var gm = get_node_or_null("/root/GameManager")
		var is_unlocked = i < (gm.unlocked_levels if gm else 1)
		
		if lock:
			lock.visible = not is_unlocked
		if play_btn:
			play_btn.disabled = not is_unlocked
			_style_button(play_btn) # Apply style to play buttons
			
			if not play_btn.pressed.is_connected(_on_play_pressed):
				play_btn.pressed.connect(_on_play_pressed.bind(i))

# Animation Callbacks
func _on_card_hover(card: Control):
	var tween = create_tween()
	tween.tween_property(card, "scale", Vector2(1.05, 1.05), 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _on_card_exit(card: Control):
	var tween = create_tween()
	tween.tween_property(card, "scale", Vector2(1.0, 1.0), 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _on_play_pressed(index: int):
	var gm = get_node_or_null("/root/GameManager")
	var level_to_load = gm.levels[index] if gm else ""
	if level_to_load == "": return
	if has_node("/root/LoadingManager"):
		get_node("/root/LoadingManager").load_level(level_to_load)
	else:
		get_tree().change_scene_to_file(level_to_load)

func _on_next_pressed():
	var gm = get_node_or_null("/root/GameManager")
	if gm and current_index < gm.levels.size() - 1:
		current_index += 1
		_snap_to_current()

func _on_prev_pressed():
	if current_index > 0:
		current_index -= 1
		_snap_to_current()

func _snap_to_current():
	var target_x = current_index * card_width
	var tween = create_tween()
	tween.tween_property(scroll_container, "scroll_horizontal", target_x, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _on_back_pressed():
	get_tree().change_scene_to_file("res://start_screen.tscn")

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
