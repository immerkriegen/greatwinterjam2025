extends CharacterBody3D
@export_group("Camera")
@export_range(0.0, 1.0) var mouse_sensitivity := 0.25

# Character constainrs
@export_group("Movement")
@export var move_speed := 8.0
@export var acceleration := 20.0
@export var rotation_speed := 12.0
@export var stopping_speed := 1.0
@export var jump_force := 12.0
@export var falling_gravity_multiplier: float = 0.5  # Reduce gravity to 50% while falling from a dash

@onready var camera_pivot: Node3D = %CamPivot
@onready var camera: Camera3D = %PlayerCam
@onready var skin: Node3D = %PlayerModel

#dash implementation
@export_group("JumpPack")
@export var dash_speed: float = 20.0       # Speed of the dash
@export var dash_duration: float = 0.2    # How long the dash lasts (in seconds)
@export var dash_cooldown: float = 1.0    # Cooldown between dashes
@export var max_boost: int = 3            # Maximum boost points
@export var boost_recharge_rate: float = 1.0  # Time to recharge one boost point
@export var ground_recharge_rate: float = 1.0 

@export var current_boost: int = 3                # Current available boosts
@export var dash_timer: float = 0.0               # Timer for the dash
@export var dash_cooldown_timer: float = 0.0      # Timer for cooldown
@export var is_dashing: bool = false              # Is the player currently dashing?
var velocity_before_dash: Vector3         # To restore velocity after dash


var camera_input_direction := Vector2.ZERO
#stores the last direction based on player's input
var _last_movement_direction := Vector3.BACK

#gravity
@export var gravity := -30.0

## Capture player's mouse
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("left_click"):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		# escape key pressed
	if event.is_action_pressed("ui_cancel"):
		# releases cursor allowing the player to move 
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	var is_camera_motion := (
		event is InputEventMouseMotion and 
		#check if mouse is on the screen
		Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED
	)
	if is_camera_motion:
		camera_input_direction = event.screen_relative * mouse_sensitivity

func _physics_process(delta: float) -> void:
	camera_pivot.rotation.x += camera_input_direction.y * delta
	#-30 degrees to 60 degrees
	camera_pivot.rotation.x = clamp(camera_pivot.rotation.x, -PI / 2.0, PI / 2.0)
	
	camera_pivot.rotation.y -= camera_input_direction.x * delta
	
	camera_input_direction = Vector2.ZERO
	
	# vectors depending on player input
	var raw_input := Input.get_vector("left", "right", "up", "down")
	var forward := camera.global_basis.z
	var right := camera.global_basis.x 
				
	if is_dashing:
		dash_timer -= delta
		if dash_timer <= 0.0:
			stop_dash()
	elif is_on_floor():
		# Recharge boost points only when grounded
		if current_boost < max_boost:
			dash_cooldown_timer -= delta * ground_recharge_rate
			if dash_cooldown_timer <= 0.0:
				current_boost += 1
				dash_cooldown_timer = dash_cooldown  # Reset the cooldown timer
			
	var move_direction := forward * raw_input.y + right * raw_input.x
	move_direction.y = 0.0
	move_direction = move_direction.normalized()
	
	var target_angle := Vector3.BACK.signed_angle_to(_last_movement_direction, Vector3.UP)
	skin.global_rotation.y = lerp_angle(skin.rotation.y, target_angle, rotation_speed * delta)

	
	#implement gravity
	var y_velocity := velocity.y

	velocity.y = 0.0
	if is_dashing:
		velocity = velocity.move_toward(move_direction * move_speed, acceleration * delta)
		velocity.y = velocity_before_dash.y
	else:
		if y_velocity < 0.0 and not is_on_floor():
			y_velocity += gravity * falling_gravity_multiplier * delta
		else:
			y_velocity += gravity * delta
			
	if is_equal_approx(move_direction.length_squared(), 0.0) and velocity.length_squared() < stopping_speed:
		velocity = Vector3.ZERO
	
	#add gravity
	velocity.y = y_velocity
	
	if move_direction.length() > 0.2:
		_last_movement_direction = move_direction

	
	if Input.is_action_just_pressed("right_click"):
		start_dash(delta)
	
	velocity = velocity.move_toward(move_direction * move_speed, acceleration * delta)
	move_and_slide()
	
	
func _process(delta: float) -> void:
	pass

	# set anims up!
	# check if character has a certain move speed (whether idle or run)
	#if is_starting_jump:
		#skin.jump()
	#	print_debug("starting jump")
	#elif not is_on_floor() and velocity.y < 0:
		#skin.fall()
	#	print_debug("falling")
	#elif is_on_floor():
	#	var ground_speed := velocity.length()
	#	if ground_speed > 0.0:
			#skin.move()
	#		print_debug("moving")
	#	else:
			#skin.idle()
	#		print_debug("idle")

func zoom_in_cam() -> void:
	pass
	
func zoom_out_cam() -> void:
	pass

func start_dash(delta: float) -> void:
	print_debug("dashing")
	# Consume a boost point
	current_boost -= 1

	# Start dashing
	is_dashing = true
	dash_timer = dash_duration
	dash_cooldown_timer = dash_cooldown 

	# Store current velocity for later restoration
	velocity_before_dash = velocity 

	# Calculate dash direction using the camera's full 3D forward vector
	var camera_forward = camera_pivot.transform.basis.z.normalized()

	# Apply dash velocity in the full 3D direction
	velocity = camera_forward * dash_speed  # Note the negative sign because Z points backward in Godot

func stop_dash() -> void:
	# Stop dashing and restore previous velocity
	is_dashing = false
	velocity = velocity_before_dash
