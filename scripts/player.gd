extends CharacterBody3D
class_name PlayerController

# -----------------------------------------------------------------------------
# Configuration Constants
# -----------------------------------------------------------------------------
const WALK_SPEED: float = 3.5
const RUN_SPEED: float = 7.0
const JUMP_VELOCITY: float = 5.0
const ACCELERATION: float = 16.0
const DECELERATION: float = 20.0
const ROTATION_SPEED: float = 12.0
const MOUSE_SENSITIVITY: float = 0.0025
const MAX_STEP_HEIGHT: float = 0.35

# -----------------------------------------------------------------------------
# Animation Preloads
# -----------------------------------------------------------------------------
const ANIM_JUMP_SCENE = preload("res://assets/animations/Happy Idle_Jump Animation.fbx")
const ANIM_RUN_SCENE = preload("res://assets/animations/Happy Idle_Run Animation.fbx")
const ANIM_WALK_SCENE = preload("res://assets/animations/Happy Idle_Walk Animation.fbx")
const ANIM_STAIRS_SCENE = preload("res://assets/animations/Happy Idle_Walk Up The Stairs Animation.fbx")

# -----------------------------------------------------------------------------
# Node References
# -----------------------------------------------------------------------------
@onready var visuals: Node3D = $Visuals
@onready var camera_pivot: Node3D = $CameraPivot
@onready var spring_arm: SpringArm3D = $CameraPivot/SpringArm3D
@onready var camera: Camera3D = $CameraPivot/SpringArm3D/Camera3D

var anim_player: AnimationPlayer = null
var current_anim: String = ""
var camera_rot_x: float = -0.15 # initial slight downward angle
var camera_rot_y: float = 0.0

# Gravity from ProjectSettings with fallback
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)
var is_movement_enabled: bool = true
var allow_stair_animation: bool = true
var stair_climbing_timer: float = 0.0
var prev_y_pos: float = 0.0

# -----------------------------------------------------------------------------
# Lifecycle
# -----------------------------------------------------------------------------
func _ready() -> void:
	add_to_group("player")
	
	# Capture mouse by default for smooth camera control
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	# Configure floor snapping and slope handling
	floor_snap_length = 0.5
	floor_max_angle = deg_to_rad(55.0)
	floor_constant_speed = true
	floor_stop_on_slope = true
	floor_block_on_wall = true
	wall_min_slide_angle = deg_to_rad(15.0)
	
	prev_y_pos = global_position.y
	
	# Setup animation player and animations
	_setup_animations()
	
	# Check and normalize visual model scale
	_normalize_visual_scale()

func set_movement_enabled(enabled: bool) -> void:
	is_movement_enabled = enabled
	if not enabled:
		velocity.x = 0.0
		velocity.z = 0.0
		if anim_player and current_anim != "idle":
			_play_anim("idle")

func _input(event: InputEvent) -> void:
	# Debug coordinate printing (Press P, C, or F3)
	if event is InputEventKey and event.pressed and not event.is_echo():
		if event.keycode == KEY_P or event.keycode == KEY_C or event.keycode == KEY_F3:
			var pos = global_position
			var coord_str = "Vector3(%.2f, %.2f, %.2f)" % [pos.x, pos.y, pos.z]
			print("==================================================")
			print("📍 Character Position: %s" % coord_str)
			print("   Raw: Vector3(%f, %f, %f)" % [pos.x, pos.y, pos.z])
			print("==================================================")
			DisplayServer.clipboard_set(coord_str)
			
	if not is_movement_enabled:
		return
		
	# Mouse look handling
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		camera_rot_y -= event.relative.x * MOUSE_SENSITIVITY
		camera_rot_x -= event.relative.y * MOUSE_SENSITIVITY
		# Clamp vertical pitch between -75 degrees and +60 degrees
		camera_rot_x = clampf(camera_rot_x, deg_to_rad(-75.0), deg_to_rad(60.0))
		
		camera_pivot.rotation.y = camera_rot_y
		spring_arm.rotation.x = camera_rot_x
		
	# Toggle mouse capture with Escape or Tab
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

# -----------------------------------------------------------------------------
# Physics & Movement Loop
# -----------------------------------------------------------------------------
func _physics_process(delta: float) -> void:
	if stair_climbing_timer > 0.0:
		stair_climbing_timer -= delta

	# 1. Apply Gravity & Ground Check
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		# Reset downward vertical accumulation when grounded
		if velocity.y < 0.0:
			velocity.y = 0.0
			
		# Jump handling
		var jump_pressed = (Input.is_action_just_pressed("jump") or Input.is_key_pressed(KEY_SPACE)) if is_movement_enabled else false
		if jump_pressed:
			velocity.y = JUMP_VELOCITY

	# 2. Gather Movement Input
	var raw_input = _get_movement_input() if is_movement_enabled else Vector2.ZERO
	var is_sprinting = (Input.is_action_pressed("sprint") or Input.is_key_pressed(KEY_SHIFT)) if is_movement_enabled else false
	var target_speed = RUN_SPEED if is_sprinting else WALK_SPEED

	# 3. Calculate Camera-Relative Movement Direction
	var move_dir = Vector3.ZERO
	if raw_input.length_squared() > 0.001:
		var cam_forward = -camera.global_transform.basis.z
		var cam_right = camera.global_transform.basis.x
		# Flatten to horizontal XZ plane
		cam_forward.y = 0.0
		cam_right.y = 0.0
		cam_forward = cam_forward.normalized()
		cam_right = cam_right.normalized()
		
		move_dir = (cam_right * raw_input.x + cam_forward * raw_input.y).normalized()

	# 4. Accelerate / Decelerate Horizontal Velocity
	var h_vel = Vector3(velocity.x, 0.0, velocity.z)
	var target_h_vel = move_dir * target_speed
	
	if move_dir.length_squared() > 0.001:
		h_vel = h_vel.move_toward(target_h_vel, ACCELERATION * delta)
		# Rotate character visuals smoothly towards movement direction
		var target_angle = atan2(move_dir.x, move_dir.z)
		visuals.rotation.y = lerp_angle(visuals.rotation.y, target_angle, ROTATION_SPEED * delta)
	else:
		h_vel = h_vel.move_toward(Vector3.ZERO, DECELERATION * delta)

	velocity.x = h_vel.x
	velocity.z = h_vel.z

	# 5. Stair Step-Up Check (Climb Steps Without Obstruction)
	if is_on_floor() and move_dir.length_squared() > 0.001:
		_snap_up_stairs_check(delta, move_dir)

	# 6. Move Character using Godot 4 CharacterBody3D physics
	move_and_slide()

	# Only count stair climbing timer if specifically stepped up via _snap_up_stairs_check
	prev_y_pos = global_position.y

	# 7. Update Animations
	_update_animation(h_vel.length(), is_sprinting)

# -----------------------------------------------------------------------------
# Smooth Stair Step-Up Handler
# -----------------------------------------------------------------------------
func _snap_up_stairs_check(delta: float, move_dir: Vector3) -> void:
	# Test if there is a step directly ahead that blocks normal ground travel
	var step_dist = max(0.12, (velocity.length() * delta) + 0.05)
	var forward_motion = move_dir * step_dist
	
	# If we can move forward freely, no step-up needed
	if not test_move(global_transform, forward_motion):
		return
		
	# There is a step/wall. Test if raising the body by MAX_STEP_HEIGHT clears it
	var up_vec = Vector3(0.0, MAX_STEP_HEIGHT, 0.0)
	var up_trans = global_transform.translated(up_vec)
	
	# If we can move forward at the elevated height:
	if not test_move(up_trans, forward_motion):
		# Cast down from the forward elevated position to find the step landing
		var forward_trans = up_trans.translated(forward_motion)
		var down_motion = Vector3(0.0, -MAX_STEP_HEIGHT * 1.5, 0.0)
		var col = KinematicCollision3D.new()
		
		if test_move(forward_trans, down_motion, col):
			var norm = col.get_normal()
			# If the top surface is walkable (angle <= floor_max_angle):
			if norm.angle_to(Vector3.UP) <= floor_max_angle:
				var step_gain = MAX_STEP_HEIGHT + col.get_travel().y
				if step_gain > 0.01 and step_gain <= MAX_STEP_HEIGHT:
					global_position.y += step_gain
					if allow_stair_animation and step_gain >= 0.12:
						stair_climbing_timer = 0.35

# -----------------------------------------------------------------------------
# Input Helper
# -----------------------------------------------------------------------------
func _get_movement_input() -> Vector2:
	var dir = Vector2.ZERO
	
	# Support InputMap actions
	if Input.is_action_pressed("move_forward"): dir.y += 1.0
	if Input.is_action_pressed("move_backward"): dir.y -= 1.0
	if Input.is_action_pressed("move_left"): dir.x -= 1.0
	if Input.is_action_pressed("move_right"): dir.x += 1.0
	
	# Fallback directly to keys for guaranteed reliability
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP): dir.y += 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN): dir.y -= 1.0
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT): dir.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT): dir.x += 1.0

	return dir.normalized()

# -----------------------------------------------------------------------------
# Animation Management
# -----------------------------------------------------------------------------
func _setup_animations() -> void:
	# Find AnimationPlayer inside the visual model hierarchy
	anim_player = _find_animation_player(visuals)
	if not anim_player:
		push_warning("Player: AnimationPlayer not found in visuals tree.")
		return
		
	# Ensure default library exists
	if not anim_player.has_animation_library(""):
		anim_player.add_animation_library("", AnimationLibrary.new())
		
	var default_lib = anim_player.get_animation_library("")
	
	# Check if the character FBX has its own idle animation
	var existing_anims = anim_player.get_animation_list()
	for anim_name in existing_anims:
		var anim = anim_player.get_animation(anim_name)
		if anim:
			anim.loop_mode = Animation.LOOP_LINEAR
			if anim_name != "idle" and not default_lib.has_animation("idle"):
				default_lib.add_animation("idle", anim.duplicate())
				
	# Register external animation clips
	_register_anim_clip("jump", ANIM_JUMP_SCENE, false)
	_register_anim_clip("run", ANIM_RUN_SCENE, true)
	_register_anim_clip("walk", ANIM_WALK_SCENE, true)
	_register_anim_clip("walk_stairs", ANIM_STAIRS_SCENE, true)
	
	# Start in idle state
	_play_anim("idle")

func _register_anim_clip(target_name: String, scene: PackedScene, should_loop: bool) -> void:
	if not scene or not anim_player:
		return
	var inst = scene.instantiate()
	var source_player = _find_animation_player(inst)
	if source_player:
		var anim_names = source_player.get_animation_list()
		for a_name in anim_names:
			var anim = source_player.get_animation(a_name)
			if anim:
				var anim_copy = anim.duplicate()
				anim_copy.loop_mode = Animation.LOOP_LINEAR if should_loop else Animation.LOOP_NONE
				var lib = anim_player.get_animation_library("")
				if lib:
					if lib.has_animation(target_name):
						lib.remove_animation(target_name)
					lib.add_animation(target_name, anim_copy)
				break
	inst.queue_free()

func _update_animation(h_speed: float, is_sprinting: bool) -> void:
	if not anim_player:
		return
		
	var target_anim = "idle"
	
	if not is_on_floor():
		target_anim = "jump"
	elif allow_stair_animation and stair_climbing_timer > 0.0 and anim_player.has_animation("walk_stairs"):
		target_anim = "walk_stairs"
	elif h_speed > 4.5 or (h_speed > 0.2 and is_sprinting):
		target_anim = "run"
	elif h_speed > 0.15:
		target_anim = "walk"
	else:
		target_anim = "idle"
		
	_play_anim(target_anim)

func _play_anim(anim_name: String) -> void:
	if not anim_player:
		return
	if current_anim == anim_name:
		return
	if anim_player.has_animation(anim_name):
		current_anim = anim_name
		anim_player.play(anim_name, 0.2)
	elif anim_player.has_animation("idle"):
		current_anim = "idle"
		anim_player.play("idle", 0.2)

# -----------------------------------------------------------------------------
# Helpers
# -----------------------------------------------------------------------------
func _find_animation_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node
	for child in node.get_children():
		var res = _find_animation_player(child)
		if res:
			return res
	return null

func _normalize_visual_scale() -> void:
	var mesh_inst = _find_first_mesh_instance(visuals)
	if mesh_inst and mesh_inst.mesh:
		var aabb = mesh_inst.mesh.get_aabb()
		# If raw mesh size in Y is over 50 (Mixamo centimeter units), scale by 0.01
		if aabb.size.y > 50.0:
			visuals.scale = Vector3(0.01, 0.01, 0.01)

func _find_first_mesh_instance(node: Node) -> MeshInstance3D:
	if node is MeshInstance3D:
		return node
	for child in node.get_children():
		var res = _find_first_mesh_instance(child)
		if res:
			return res
	return null
