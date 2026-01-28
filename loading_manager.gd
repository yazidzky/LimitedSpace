extends Node

var loading_screen_scene = load("res://loading_screen.tscn")
var loading_screen_instance = null
var scene_path_to_load = ""
var load_status = 0
var progress = []

func load_level(path: String):
	scene_path_to_load = path
	
	# Instantiate and show loading screen
	if loading_screen_instance:
		loading_screen_instance.queue_free()
	
	loading_screen_instance = loading_screen_scene.instantiate()
	get_tree().root.add_child(loading_screen_instance)
	
	# Start background loading
	ResourceLoader.load_threaded_request(scene_path_to_load)
	set_process(true)

func _process(_delta):
	if scene_path_to_load == "":
		set_process(false)
		return
		
	load_status = ResourceLoader.load_threaded_get_status(scene_path_to_load, progress)
	
	if loading_screen_instance:
		var p = 0.0
		if progress.size() > 0:
			p = progress[0]
		loading_screen_instance.set_progress(p)
	
	if load_status == ResourceLoader.THREAD_LOAD_LOADED:
		set_process(false)
		_on_load_complete()
	elif load_status == ResourceLoader.THREAD_LOAD_FAILED or load_status == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
		set_process(false)
		print("Error loading scene: ", scene_path_to_load)
		if loading_screen_instance:
			loading_screen_instance.set_status("Error Loading Level")

func _on_load_complete():
	if loading_screen_instance:
		loading_screen_instance.set_status("Rendering Collision Map...")
	
	var new_scene_resource = ResourceLoader.load_threaded_get(scene_path_to_load)
	
	# Change the scene
	# This might freeze the main thread for a bit
	get_tree().change_scene_to_packed(new_scene_resource)
	
	# Notify AudioManager to play new music
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").play_music_for_scene(new_scene_resource.resource_path.get_file().get_basename())
	
	# Wait for "Collision Map" (Physics Initialization)
	# We wait for the new scene to be fully in the tree + physics frames
	await _wait_for_physics_stabilization()
	
	# Remove loading screen
	if loading_screen_instance:
		loading_screen_instance.queue_free()
		loading_screen_instance = null
	
	scene_path_to_load = ""

func _wait_for_physics_stabilization():
	# Wait for the scene change to actually happen (next frame)
	await get_tree().process_frame 
	
	# Now the new scene is active, but physics might not be ready
	print("New scene active. Waiting for collision/physics...")
	
	if loading_screen_instance:
		loading_screen_instance.set_status("Rendering Collision Map...")
	
	# Wait for a few physics frames to ensure collision map is built
	# For large maps, this is crucial. We simulate a "100%" progress here.
	var total_frames = 40 # Increased to ensure stability
	
	for i in range(total_frames):
		await get_tree().physics_frame
		
		# Update percentage for user feedback
		if loading_screen_instance:
			var percent = int((float(i) / float(total_frames)) * 100)
			loading_screen_instance.set_status("Rendering Collision Map: %d%%" % percent)
	
	if loading_screen_instance:
		loading_screen_instance.set_status("Rendering Collision Map: 100%")
	
	# One final wait just to be sure
	await get_tree().physics_frame
	
	print("Physics stabilized. Hiding loading screen.")
