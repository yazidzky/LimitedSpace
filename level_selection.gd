extends Control

@onready var scroll_container = %ScrollContainer
@onready var h_box = %HBoxContainer

var current_index = 0
var card_width = 400 # Width of each level card + separation

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_update_cards()
	_snap_to_current()
	
	%NextButton.pressed.connect(_on_next_pressed)
	%PrevButton.pressed.connect(_on_prev_pressed)
	%BackButton.pressed.connect(_on_back_pressed)

func _update_cards():
	var cards = h_box.get_children()
	var preview_images = [
		"res://Previewlevel/tutorialmap_preview.png",
		"res://Previewlevel/map1_preview.png",
		"res://Previewlevel/map2_preview.png",
		"res://Previewlevel/map3_preview.png"
	]
	
	for i in range(cards.size()):
		var card = cards[i]
		var lock = card.get_node_or_null("LockIcon")
		var play_btn = card.get_node_or_null("PlayButton")
		
		# Setup 2D Preview
		var preview_container = card.get_node_or_null("PreviewContainer")
		if preview_container and i < preview_images.size():
			# Clear previous preview if any
			for child in preview_container.get_children():
				child.queue_free()
				
			var texture_rect = TextureRect.new()
			texture_rect.texture = load(preview_images[i])
			texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			texture_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			preview_container.add_child(texture_rect)
		
		var gm = get_node_or_null("/root/GameManager")
		var is_unlocked = i < (gm.unlocked_levels if gm else 1)
		
		if lock:
			lock.visible = not is_unlocked
		if play_btn:
			play_btn.disabled = not is_unlocked
			if not play_btn.pressed.is_connected(_on_play_pressed):
				play_btn.pressed.connect(_on_play_pressed.bind(i))

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
