extends CanvasLayer

@onready var label = $Label

func set_progress(value: float):
	label.text = "Loading... %d%%" % int(value * 100)

func set_status(text: String):
	label.text = text
