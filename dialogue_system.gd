extends CanvasLayer

signal dialogue_finished

@onready var panel = %DialoguePanel
@onready var name_label = %NameLabel
@onready var text_label = %TextLabel
@onready var next_button = %NextButton

var current_lines: Array = []
var current_index: int = 0
var typing_speed: float = 0.02
var is_typing: bool = false

# STORY DATABASE
var story_data = {
	"intro": [
		{"name": "System", "text": "Initiating Sequence 00-Alpha..."},
		{"name": "System", "text": "Subject: Sophia. Status: Rebooting."},
		{"name": "Sophia", "text": "... Cold. It's so cold here."},
		{"name": "Architect", "text": "Start with the Squire's Path. Prove you can walk before you attempt to fly."}
	],
	"intro_2": [
		{"name": "System", "text": "Sequence 00-Beta Initialized."},
		{"name": "Architect", "text": "You return to the Abyss. Do you hope for a different outcome?"},
		{"name": "Sophia", "text": "I hope for answers."},
		{"name": "Architect", "text": "Answers are buried deep. Dig them out if you can."}
	],
	"intro_3": [
		{"name": "System", "text": "Data Stream: Stable."},
		{"name": "Architect", "text": "The Eternal Abyss is patient. It will wait for your failure."},
		{"name": "Sophia", "text": "I'm not going to fail."},
		{"name": "Architect", "text": "Your confidence is... noted. Proceed."}
	],
	"intro_4": [
		{"name": "Architect", "text": "Did you feel that? A ripple in the datastream."},
		{"name": "Sophia", "text": "Was it me?"},
		{"name": "Architect", "text": "You are but a drop in the ocean. But even a drop causes ripples. Continue your journey."}
	],
	"tutorial_enter": [
		{"name": "Architect", "text": "Basic motor functions check. Do not disappoint me."},
		{"name": "Sophia", "text": "I feel... heavy. But strong."},
		{"name": "Architect", "text": "Gravity is stronger here. Use it."}
	],
	"level_1_enter": [
		{"name": "Architect", "text": "The Coiled Citadel. An ancient glitch in the system that I decided to keep."},
		{"name": "Sophia", "text": "The walls... they're moving?"},
		{"name": "Architect", "text": "Static objects are boring. Adaptation is key. Survive the shift."}
	],
	"level_2_enter": [
		{"name": "Architect", "text": "Azure Depths. A liquid graveyard."},
		{"name": "Sophia", "text": "I can't swim forever."},
		{"name": "Architect", "text": "Then find solid ground. Or sink into the datastream forever. Your choice."}
	],
	"level_3_enter": [
		{"name": "Architect", "text": "Cranium Gardens. The neural center of the Abyss."},
		{"name": "Sophia", "text": "It's quiet. Too quiet."},
		{"name": "Architect", "text": "The loudest thoughts are the ones never spoken. Watch out for the guardians. They can hear your fear."}
	],
	"tutorial_end": [
		{"name": "Architect", "text": "Acceptable. You have basic competency."},
		{"name": "Sophia", "text": "Is this a test?"},
		{"name": "Architect", "text": "Everything is a test. Proceed to the Citadel."}
	],
	"level_1_end": [
		{"name": "Architect", "text": "You survived the shift. Impressive for a glitch."},
		{"name": "Sophia", "text": "I'm not a glitch. I'm me."},
		{"name": "Architect", "text": "Definitions change. Identity is fluid. Continue."}
	],
	"level_2_end": [
		{"name": "Sophia", "text": "*Gasp*... I found the exit."},
		{"name": "Architect", "text": "You swim well against the current."},
		{"name": "Architect", "text": "Only the mind remains. Are you ready to lose it?"}
	],
	"level_3_end": [
		{"name": "Architect", "text": "You have reached the core. The equation is... balanced."},
		{"name": "Sophia", "text": "Does this mean I can go?"},
		{"name": "Architect", "text": "There is no 'go'. There is only 'be'. But you have earned your rest. For now."}
	],
	"key_pickup": [
		{"name": "System", "text": "Access Fragment Acquired."},
		{"name": "Sophia", "text": "I feel a path opening..."},
	],
	"key_pickup_tutorial": [
		{"name": "Architect", "text": "A simple key. It opens the way forward. Do not lose it."}
	],
	"key_pickup_level_1": [
		{"name": "Sophia", "text": "This key... it hums with energy."},
		{"name": "Architect", "text": "It unlocks the coils. Be ready."}
	],
	"key_pickup_level_2": [
		{"name": "Sophia", "text": "It's cold to the touch."},
		{"name": "Architect", "text": "Frozen data. It will bridge the gap."}
	],
	"key_pickup_level_3": [
		{"name": "Architect", "text": "A memory shard. Be careful not to cut yourself on the past."}
	],
	"game_ending": [
		{"name": "System", "text": "CRITICAL ALERT: Simulation integrity reached 100%."},
		{"name": "Sophia", "text": "Is it... over? Everything feels so clear now."},
		{"name": "Architect", "text": "You have traversed the limited space and found the infinite within."},
		{"name": "Architect", "text": "The Abyss is no longer your prison. It is your playground."},
		{"name": "Sophia", "text": "Thank you... Architect."},
		{"name": "System", "text": "Ending Sequence: Finalized. Subject Status: Awakened."}
	],
	"game_completed_greeting": [
		{"name": "Architect", "text": "The Master of the Abyss returns."},
		{"name": "Sophia", "text": "I feel different. I'm not afraid anymore."},
		{"name": "Architect", "text": "Your progress is recorded. You are free to roam or refine your skills."}
	]
}

func _ready():
	visible = false
	next_button.pressed.connect(advance_dialogue)

func start_dialogue(story_key: String):
	if story_key in story_data:
		current_lines = story_data[story_key]
		current_index = 0
		visible = true
		show_current_line()
	else:
		print("Dialog key not found: ", story_key)
		emit_signal("dialogue_finished")

func show_current_line():
	if current_index >= current_lines.size():
		close_dialogue()
		return
	
	var data = current_lines[current_index]
	name_label.text = data["name"]
	
	# Simple color coding
	if data["name"] == "Sophia":
		name_label.modulate = Color("5dcaff") # Light Blue
	elif data["name"] == "Architect" or data["name"] == "???":
		name_label.modulate = Color("ff4d4d") # Red
	elif data["name"] == "System":
		name_label.modulate = Color("00ff00") # Green
	else:
		name_label.modulate = Color.WHITE
		
	# Typing effect
	text_label.text = data["text"]
	text_label.visible_ratio = 0.0
	is_typing = true
	
	var tween = create_tween()
	var duration = data["text"].length() * typing_speed
	tween.tween_property(text_label, "visible_ratio", 1.0, duration)
	tween.finished.connect(func(): is_typing = false)

func advance_dialogue():
	if is_typing:
		# Skip typing
		var tween = get_tree().create_tween()
		tween.kill() # Stop existing tweens (simplification)
		text_label.visible_ratio = 1.0
		is_typing = false
	else:
		current_index += 1
		show_current_line()

func close_dialogue():
	visible = false
	emit_signal("dialogue_finished")

func _input(event):
	if visible and event.is_action_pressed("ui_accept"): # Enter/Space to advance
		advance_dialogue()
