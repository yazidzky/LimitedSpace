extends Node

var _music_player: AudioStreamPlayer
var _current_track: String = ""

# Level to Music mapping based on user request
var _level_music = {
	"tutorial": "res://Musik/Borealis.mp3",
	"level_1": "res://Musik/Old_Chimney_maintheme.mp3",
	"level_2": "res://Musik/Clair Obscur_ Expedition 33 (Original Soundtrack) 100 - Sirène - Robe de Jour.mp3",
	"level_3": "res://Musik/Clair Obscur_ Expedition 33 - Gustave (Original Soundtrack).mp3"
}

# Volume settings
var music_volume_db: float = -10.0 # Adjust as needed

func _ready():
	_music_player = AudioStreamPlayer.new()
	_music_player.bus = "Music" # Optional: ensure you have a 'Music' bus in your project
	add_child(_music_player)
	_music_player.volume_db = music_volume_db
	
	# Initial check for the current scene
	play_music_for_scene(get_tree().current_scene.name)

func play_music_for_scene(scene_name: String):
	var key = scene_name.to_lower()
	
	# Fuzzy matching for level names
	var track_path = ""
	if "tutorial" in key:
		track_path = _level_music["tutorial"]
	elif "level_1" in key or "map1" in key or "level 1" in key:
		track_path = _level_music["level_1"]
	elif "level_2" in key or "map_2" in key or "level 2" in key:
		track_path = _level_music["level_2"]
	elif "level_3" in key or "map3" in key or "level 3" in key:
		track_path = _level_music["level_3"]
	
	if track_path != "" and track_path != _current_track:
		_play_track(track_path)

func _play_track(path: String):
	if not FileAccess.file_exists(path):
		print("AudioManager Error: Music file not found at ", path)
		return
		
	var stream = load(path)
	if stream:
		# Compatibility note: WAV files might need loop settings in the importer
		# MP3 files in Godot 4 usually loop if configured on the stream
		if stream is AudioStreamMP3:
			stream.loop = true
		elif stream is AudioStreamWAV:
			stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
			
		_music_player.stream = stream
		_music_player.play()
		_current_track = path
		print("AudioManager: Playing ", path)

func set_volume(volume_db: float):
	music_volume_db = volume_db
	if _music_player:
		_music_player.volume_db = music_volume_db
