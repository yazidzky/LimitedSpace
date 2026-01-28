extends Control

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
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
