extends Node

var _music_player: AudioStreamPlayer
var _current_track: String = ""

# Level to Music mapping based on user request
var _level_music = {
	"tutorial": "res://Musik/Borealis.mp3",
	"level_1": "res://Musik/Old_Chimney_maintheme.mp3",
	"level_2": "res://Musik/level_2_music.mp3",
	"level_3": "res://Musik/level_3_music.mp3",
	"start_screen": "res://Musik/menu_music.mp3",
	"level_selection": "res://Musik/menu_music.mp3"
}

# Volume settings
var music_volume_db: float = -10.0 # Adjust as needed

func _ready():
	_music_player = AudioStreamPlayer.new()
	add_child(_music_player)
	
	# Fallback to Master if Music bus isn't defined in the project
	if AudioServer.get_bus_index("Music") != -1:
		_music_player.bus = "Music"
	else:
		_music_player.bus = "Master"
		print("AudioManager: 'Music' bus not found, falling back to 'Master'")
	
	_music_player.volume_db = music_volume_db
	
	# Initial check for the current scene
	if get_tree().current_scene:
		play_music_for_scene(get_tree().current_scene.name)

func play_music_for_scene(scene_name: String):
	var key = scene_name.to_lower()
	
	# Fuzzy matching for level names
	var track_path = ""
	var volume_offset = 0.0
	
	if "tutorial" in key:
		track_path = _level_music["tutorial"]
	elif "level_1" in key or "map1" in key or "level 1" in key:
		track_path = _level_music["level_1"]
	elif "level_2" in key or "map_2" in key or "level 2" in key:
		track_path = _level_music["level_2"]
	elif "level_3" in key or "map3" in key or "level 3" in key:
		track_path = _level_music["level_3"]
	elif "start_screen" in key:
		track_path = _level_music["start_screen"]
		volume_offset = 12.0 # Make entrance music much louder as requested
	elif "level_selection" in key:
		track_path = _level_music["level_selection"]
		volume_offset = 12.0 # Make entrance music much louder as requested
	
	if track_path != "" and track_path != _current_track:
		_play_track(track_path, volume_offset)

func _play_track(path: String, offset: float = 0.0):
	if not FileAccess.file_exists(path):
		print("AudioManager Error: Music file not found at ", path)
		return
		
	var stream = load(path)
	if stream:
		_music_player.volume_db = music_volume_db + offset
		
		# Compatibility note: WAV files might need loop settings in the importer
		if stream is AudioStreamMP3:
			stream.loop = true
		elif stream is AudioStreamWAV:
			stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
			
		_music_player.stream = stream
		_music_player.play()
		_current_track = path
		print("AudioManager: Successfully playing ", path, " with offset ", offset)
	else:
		print("AudioManager Error: Failed to load music stream from ", path)
		# Try to check if special characters are the issue
		if "è" in path or "(" in path or " " in path:
			print("AudioManager Hint: Filename contains special characters or spaces which can fail in exports. Consider renaming files.")

func set_volume(volume_db: float):
	music_volume_db = volume_db
	if _music_player:
		_music_player.volume_db = music_volume_db
