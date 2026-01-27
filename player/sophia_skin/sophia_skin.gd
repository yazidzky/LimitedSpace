class_name SophiaSkin extends Node3D

@onready var animation_tree: AnimationTree = %AnimationTree
@onready var state_machine: AnimationNodeStateMachinePlayback = animation_tree.get("parameters/StateMachine/playback")
@onready var move_tilt_path : String = "parameters/StateMachine/Move/tilt/add_amount"

var run_tilt = 0.0 : set = _set_run_tilt

@export var blink = true : set = set_blink
@onready var blink_timer = %BlinkTimer
@onready var closed_eyes_timer = %ClosedEyesTimer
@onready var eye_mat = $sophia/rig/Skeleton3D/Sophia.get("surface_material_override/2")

var xray_shader = preload("res://player_xray.gdshader")

func _ready():
	_apply_xray_material(self)
	
	blink_timer.connect("timeout", func():
		eye_mat.set("uv1_offset", Vector3(0.0, 0.5, 0.0))
		closed_eyes_timer.start(0.2)
		)
		
	closed_eyes_timer.connect("timeout", func():
		eye_mat.set("uv1_offset", Vector3.ZERO)
		blink_timer.start(randf_range(1.0, 4.0))
		)

func _apply_xray_material(node: Node):
	if node is MeshInstance3D:
		var xray_mat = ShaderMaterial.new()
		xray_mat.shader = xray_shader
		xray_mat.render_priority = 10
		xray_mat.set_shader_parameter("silhouette_color", Color(0.0, 0.6, 1.0, 0.4))
		
		# Set material_overlay. Make sure it's not and-ing with anything
		node.material_overlay = xray_mat
			
	for child in node.get_children():
		_apply_xray_material(child)

func set_blink(state : bool):
	if blink == state: return
	blink = state
	if blink:
		blink_timer.start(0.2)
	else:
		blink_timer.stop()
		closed_eyes_timer.stop()

func _set_run_tilt(value : float):
	run_tilt = clamp(value, -1.0, 1.0)
	animation_tree.set(move_tilt_path, run_tilt)

func idle():
	state_machine.travel("Idle")

func move():
	state_machine.travel("Move")

func fall():
	state_machine.travel("Fall")

func jump():
	state_machine.travel("Jump")

func edge_grab():
	state_machine.travel("EdgeGrab")

func wall_slide():
	state_machine.travel("WallSlide")
