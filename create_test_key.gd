extends Node3D
# Helper script to create a proper key scene
# Attach this to any Node3D in your scene and run the game to create a key

func _ready():
	print("=== KEY SCENE CREATOR ===")
	create_key_at_position(Vector3(0, 2, 0))

func create_key_at_position(pos: Vector3):
	# Create Area3D (root)
	var key = Area3D.new()
	key.name = "Key_Generated"
	key.position = pos
	
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
	shape.radius = 1.0
	collision.shape = shape
	key.add_child(collision)
	collision.owner = key
	
	# Create visual (simple cube for now)
	var visual = MeshInstance3D.new()
	visual.name = "Visual"
	var mesh = BoxMesh.new()
	mesh.size = Vector3(0.5, 0.5, 0.5)
	visual.mesh = mesh
	
	# Make it golden/yellow
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(1.0, 0.8, 0.0)  # Gold color
	material.metallic = 0.8
	material.roughness = 0.2
	material.emission_enabled = true
	material.emission = Color(1.0, 0.9, 0.3)
	material.emission_energy_multiplier = 2.0
	visual.set_surface_override_material(0, material)
	
	key.add_child(visual)
	visual.owner = key
	
	# Add to scene
	get_tree().root.add_child(key)
	
	print("✅ KEY CREATED at position: ", pos)
	print("   - Type: Area3D")
	print("   - Collision Layer: 1 (World)")
	print("   - Collision Mask: 2 (Player)")
	print("   - Script: key.gd attached")
	print("   - Visual: Golden cube")
	print("")
	print("🎮 Try touching it with your player!")
