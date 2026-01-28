extends Node

const SAVE_PATH = "user://saves.cfg"

var unlocked_levels = 1 # 1: Tutorial unlocked, 2: Level 1 unlocked, etc.
var levels = [
	"res://Tutorial.tscn",
	"res://level_1.tscn",
	"res://level_2.tscn",
	"res://Map/level_3.tscn"
]

func _ready():
	load_game()

func complete_level(level_path: String):
	var level_index = -1
	for i in range(levels.size()):
		if levels[i] == level_path:
			level_index = i
			break
	
	if level_index != -1 and level_index == unlocked_levels - 1:
		unlocked_levels = clampi(level_index + 2, 1, levels.size())
		save_game()
		print("GameManager: Level %d completed. Unlocked levels: %d" % [level_index, unlocked_levels])

func save_game():
	var config = ConfigFile.new()
	config.set_value("progression", "unlocked_levels", unlocked_levels)
	config.save(SAVE_PATH)

func load_game():
	var config = ConfigFile.new()
	var err = config.load(SAVE_PATH)
	if err == OK:
		unlocked_levels = config.get_value("progression", "unlocked_levels", 1)
