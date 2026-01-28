extends Control

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	%StartButton.pressed.connect(_on_start_pressed)
	%LevelSelectionButton.pressed.connect(_on_level_selection_pressed)
	%CreditsButton.pressed.connect(_on_credits_pressed)
	%ExitButton.pressed.connect(_on_exit_pressed)
	%CloseCreditsButton.pressed.connect(_on_close_credits_pressed)

func _on_start_pressed():
	var gm = get_node_or_null("/root/GameManager")
	var level_to_load = gm.levels[0] if gm else "res://Tutorial.tscn"
	if has_node("/root/LoadingManager"):
		get_node("/root/LoadingManager").load_level(level_to_load)
	else:
		get_tree().change_scene_to_file(level_to_load)

func _on_level_selection_pressed():
	get_tree().change_scene_to_file("res://level_selection.tscn")

func _on_credits_pressed():
	%CreditsPanel.visible = true

func _on_close_credits_pressed():
	%CreditsPanel.visible = false

func _on_exit_pressed():
	get_tree().quit()
