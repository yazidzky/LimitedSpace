extends CanvasLayer

func _ready():
	# Make sure it appears above everything
	layer = 100
	
	# Create a dark background overlay
	var color_rect = ColorRect.new()
	color_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	color_rect.color = Color(0, 0, 0, 0.5)
	add_child(color_rect)
	
	var panel = PanelContainer.new()
	# Center the panel
	panel.set_anchors_preset(Control.PRESET_CENTER)
	# Grow direction both to keep it centered
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	add_child(panel)
	
	var vbox = VBoxContainer.new()
	# Add some margin
	var margin_container = MarginContainer.new()
	margin_container.add_theme_constant_override("margin_top", 20)
	margin_container.add_theme_constant_override("margin_bottom", 20)
	margin_container.add_theme_constant_override("margin_left", 20)
	margin_container.add_theme_constant_override("margin_right", 20)
	margin_container.add_child(vbox)
	panel.add_child(margin_container)
	
	var title = Label.new()
	title.text = "WARNING"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color(1, 0.2, 0.2)) # Reddish
	title.add_theme_font_size_override("font_size", 24)
	vbox.add_child(title)
	
	var spacer1 = Control.new()
	spacer1.custom_minimum_size = Vector2(0, 10)
	vbox.add_child(spacer1)
	
	var msg = Label.new()
	msg.text = "Be careful when left-clicking,\nas you can now climb vertical walls."
	msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(msg)
	
	var spacer2 = Control.new()
	spacer2.custom_minimum_size = Vector2(0, 20)
	vbox.add_child(spacer2)
	
	var btn = Button.new()
	btn.text = "OK"
	btn.custom_minimum_size = Vector2(100, 0)
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn.pressed.connect(_on_ok_pressed)
	vbox.add_child(btn)

func _on_ok_pressed():
	queue_free()
