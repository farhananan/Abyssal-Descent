extends CharacterBody2D

signal smash_landed(position)

const SPEED = 200.0
const JUMP_VELOCITY = -450.0
const MAX_JUMPS = 2
const SMASH_SPEED = 900.0

const DASH_SPEED = 700.0
const DASH_DURATION = 0.3
const DASH_COOLDOWN = 0.4

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var jumps_left = MAX_JUMPS
var is_smashing = false

var is_dashing = false
var dash_timer = 0.0
var dash_cooldown_timer = 0.0
var dash_vector = Vector2.RIGHT
var facing = 1.0
var can_air_dash = true

func _physics_process(delta):
	if dash_cooldown_timer > 0:
		dash_cooldown_timer -= delta

	# Active dash: no gravity, fixed velocity along the dash direction
	if is_dashing:
		dash_timer -= delta
		velocity = dash_vector * DASH_SPEED
		if dash_timer <= 0:
			is_dashing = false
			velocity.y = 0  # don't carry upward speed out of the dash
		move_and_slide()
		return

	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		jumps_left = MAX_JUMPS
		can_air_dash = true
		if is_smashing:
			_on_smash_land()

	# Start a dash
	if Input.is_action_just_pressed("dash") and dash_cooldown_timer <= 0 and not is_smashing:
		if is_on_floor() or can_air_dash:
			if not is_on_floor():
				can_air_dash = false

			var h = Input.get_axis("ui_left", "ui_right")
			if Input.is_action_pressed("ui_up") and h != 0:
				# 45 degree diagonal: up + left/right
				dash_vector = Vector2(h, -1).normalized()
			else:
				dash_vector = Vector2(facing, 0)

			is_dashing = true
			dash_timer = DASH_DURATION
			dash_cooldown_timer = DASH_COOLDOWN
			return

	# Down smash
	if Input.is_action_just_pressed("ui_down") and not is_on_floor() and not is_smashing:
		is_smashing = true
		velocity.x = 0
		velocity.y = SMASH_SPEED

	if is_smashing:
		move_and_slide()
		return

	# Jump / double jump
	if Input.is_action_just_pressed("ui_accept") and jumps_left > 0:
		velocity.y = JUMP_VELOCITY
		jumps_left -= 1

	# Left/right movement
	var direction = Input.get_axis("ui_left", "ui_right")
	if direction != 0:
		facing = sign(direction)
	velocity.x = direction * SPEED

	move_and_slide()

func _on_smash_land():
	is_smashing = false
	smash_landed.emit(global_position)
