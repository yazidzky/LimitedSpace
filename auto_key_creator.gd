extends Node3D
# Script untuk membuat key yang benar secara otomatis
# Letakkan script ini di level Anda dan jalankan game

@export var key_positions: Array[Vector3] = [Vector3(0, 2, 0)]  # Edit posisi key di Inspector

func _ready():
	print("=== AUTO KEY CREATOR ===")
	for pos in key_positions:
		create_functional_key(pos)

func create_functional_key(pos: Vector3):
	# Buat Area3D (root)
	var key = Area3D.new()
	key.name = "Key_" + str(randi())
	key.global_position = pos
	
	# Set collision layers
	key.collision_layer = 1  # World
	key.collision_mask = 2   # Player
	
	# Add to key group
	key.add_to_group("key")
	
	# Attach the script
	var script = load("res://keyOpenGate/key.gd")
	if script:
		key.set_script(script)
	
	# Create collision shape
	var collision = CollisionShape3D.new()
	var shape = SphereShape3D.new()
	shape.radius = 0.8
	collision.shape = shape
	key.add_child(collision)
	
	# Load the key model
	var key_model_scene = load("res://keyOpenGate/key.glb")
	if key_model_scene:
		var model = key_model_scene.instantiate()
		model.name = "Visual"
		model.scale = Vector3(0.3, 0.3, 0.3)  # Sesuaikan ukuran
		key.add_child(model)
	else:
		# Fallback: buat cube emas
		var visual = MeshInstance3D.new()
		visual.name = "Visual"
		var mesh = BoxMesh.new()
		mesh.size = Vector3(0.5, 0.5, 0.5)
		visual.mesh = mesh
		
		var material = StandardMaterial3D.new()
		material.albedo_color = Color(1.0, 0.8, 0.0)
		material.metallic = 0.8
		material.roughness = 0.2
		material.emission_enabled = true
		material.emission = Color(1.0, 0.9, 0.3)
		material.emission_energy_multiplier = 3.0
		visual.set_surface_override_material(0, material)
		
		key.add_child(visual)
	
	# Add to scene
	get_tree().root.add_child(key)
	
	print("✅ KEY CREATED at: ", pos)
	print("   - Type: Area3D ✓")
	print("   - Script: key.gd ✓")
	print("   - Collision: SphereShape3D ✓")
	print("   - Visual: ", "key.glb" if key_model_scene else "Golden Cube")
