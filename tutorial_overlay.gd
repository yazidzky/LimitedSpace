extends CanvasLayer

@onready var panel = %PanelContainer
@onready var label = %InstructionLabel
@onready var arrow = %ArrowPointer
# Removed AnimationPlayer dependency as it wasn't used

enum Step { ROTATE, MOVE, HUD_INFO, FIND_KEY, COMPLETED }
var current_step = Step.ROTATE
var _rotation_time = 0.0
var _initial_player_pos = Vector3.ZERO
var player: Node3D

func _ready():
	visible = true
	layer = 10 # Ensure tutorial is above other UI
	if arrow: arrow.visible = false
	_show_step(Step.ROTATE)
	
	player = get_tree().get_first_node_in_group("player")
	if player:
		_initial_player_pos = player.global_position

func _process(delta):
	match current_step:
		Step.ROTATE:
			# User asked for automatic transition when action is done
			if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
				_rotation_time += delta
				# Reduced time to feel instant/snappy
				if _rotation_time > 0.1:
					_advance_step(Step.MOVE)
		
		Step.MOVE:
			if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
				_advance_step(Step.HUD_INFO)
					
		Step.HUD_INFO:
			if Input.is_action_just_pressed("ui_accept") or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
				_advance_step(Step.FIND_KEY)
				
		Step.FIND_KEY:
			pass # Waiting for key collection (handled by level logic usually, or just leave message)

func _show_step(step):
	current_step = step
	panel.visible = true
	panel.scale = Vector2.ZERO
	if arrow: arrow.visible = false
	
	var tween = create_tween()
	tween.tween_property(panel, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	match step:
		Step.ROTATE:
			label.text = "Hold RIGHT CLICK to Rotate Camera & Scan"
		Step.MOVE:
			label.text = "Click LEFT CLICK on the Ground to Move"
		Step.HUD_INFO:
			label.text = "Check the TOP BAR\nIt shows distance to your Objective!\n(Click to Continue)"
			_highlight_bar()
		Step.FIND_KEY:
			label.text = "Find the KEY to Unlock the Exit!\n(Follow the Arrow)"
			# Activate Guide Arrow in Tutorial
			var root = get_tree().current_scene
			if root and "tutorial_guide_active" in root:
				root.tutorial_guide_active = true
				
			await get_tree().create_timer(3.0).timeout
			_hide_panel()

func _advance_step(next_step):
	# Slight delay/anim out
	current_step = next_step # Prevent multi-trigger
	if arrow: arrow.visible = false
	
	var tween = create_tween()
	tween.tween_property(panel, "scale", Vector2.ZERO, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	await tween.finished
	
	_show_step(next_step)

func _highlight_bar():
	# User requested 3D guide arrow instead of HUD arrow
	pass

func _hide_panel():
	var tween = create_tween()
	tween.tween_property(panel, "scale", Vector2.ZERO, 0.3)
	await tween.finished
	panel.visible = false
