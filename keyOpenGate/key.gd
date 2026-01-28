extends Area3D

signal collected

var _collected := false
var _time := 0.0
var _visual_node: Node3D = null

func _ready():
	# Standard Key properties
	add_to_group("key")
	print("KEY READY: ", name, " at ", global_position)
	visible = true # Ensure visible
	
	# CRITICAL FIX: Connect the body_entered signal
	if not is_connected("body_entered", _on_body_entered):
		body_entered.connect(_on_body_entered)
		print("KEY: Collision signal connected for ", name)
	
	# Set up collision layers for player detection
	collision_layer = 1  # Layer 1: World objects
	collision_mask = 1   # Mask 1: Detect player (player uses default layer 1)

	
	# Find visual node for animation (with fallback)
	_visual_node = find_child("Visual", true, false)
	if not _visual_node:
		_visual_node = find_child("Roundcube", true, false)
	if not _visual_node:
		# Use self if no visual child found
		_visual_node = self
		print("KEY WARNING: No Visual/Roundcube child found, using root node for animation")

func _process(delta):
	if _collected: return
	
	# Visual flair: Bobbing and Rotating
	_time += delta
	if _visual_node and _visual_node != self:
		_visual_node.position.y = sin(_time * 2.0) * 0.2
		_visual_node.rotate_y(delta * 1.5)

func _on_body_entered(body):
	print("KEY: Body entered - ", body.name, " | Groups: ", body.get_groups())
	if _collected: return
	
	# Only collect if player touches it
	if body.is_in_group("player") or body.name.to_lower().contains("sophia"):
		print("KEY: Player detected! Collecting...")
		_collect()


func _collect():
	if _collected: return
	_collected = true
	
	# CRITICAL: Recursively disable all collision nodes in the hierarchy
	# This ensures any StaticBody3D inside the GLB model is neutralized immediately
	var stack = [self]
	while stack.size() > 0:
		var node = stack.pop_back()
		if node is CollisionShape3D or node is CollisionPolygon3D:
			node.set_deferred("disabled", true)
		if node is PhysicsBody3D:
			node.collision_layer = 0
			node.collision_mask = 0
		stack.append_array(node.get_children())
	
	# Disable parent Area3D as well
	collision_layer = 0
	collision_mask = 0
	
	collected.emit()
	print("KEY COLLECTED: ", name)

	
	# Play VFX
	var vfx_scene = preload("res://vfx/scenes/magic_puff.tscn")
	if vfx_scene:
		var vfx = vfx_scene.instantiate()
		get_tree().root.add_child(vfx)
		vfx.global_position = global_position
		vfx.scale = Vector3(2.5, 2.5, 2.5) # Make VFX larger to match larger key
		
		# Start animation if it exists
		var anim = vfx.find_child("AnimationPlayer", true, false)
		if anim:
			anim.play("play")
			# Auto-cleanup VFX after animation
			if anim.has_animation("play"):
				var anim_length = anim.get_animation("play").length
				await get_tree().create_timer(anim_length + 0.5).timeout
				if is_instance_valid(vfx):
					vfx.queue_free()
	
	# Hide immediately
	hide()
	
	# Wait a bit before freeing the key node
	# Increased slightly to ensure VFX starts well
	await get_tree().create_timer(0.5).timeout
	queue_free()
