extends CharacterBody2D

signal smash_landed(position)

const SPEED = 150.0
const JUMP_VELOCITY = -350.0
const MAX_JUMPS = 2
const SMASH_SPEED = 900.0

const DASH_SPEED = 700.0
const DASH_DURATION = 0.15
const DASH_COOLDOWN = 0.4

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var jumps_left = MAX_JUMPS
var is_smashing = false

var is_dashing = false
var dash_timer = 0.0
var dash_cooldown_timer = 0.0
var dash_direction = 1.0
var facing = 1.0
var can_air_dash = true

func _physics_process(delta):
	# Cooldown ticks down every frame
	if dash_cooldown_timer > 0:
		dash_cooldown_timer -= delta

	# Handle an active dash first: no gravity, fixed horizontal speed
	if is_dashing:
		dash_timer -= delta
		velocity.x = dash_direction * DASH_SPEED
		velocity.y = 0
		if dash_timer <= 0:
			is_dashing = false
		move_and_slide()
		return

	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		jumps_left = MAX_JUMPS
		can_air_dash = true
		if is_smashing:
			_on_smash_land()

	# Start a dash (one per airtime, plus the cooldown)
	if Input.is_action_just_pressed("dash") and dash_cooldown_timer <= 0 and not is_smashing:
		if is_on_floor() or can_air_dash:
			if not is_on_floor():
				can_air_dash = false
			is_dashing = true
			dash_timer = DASH_DURATION
			dash_cooldown_timer = DASH_COOLDOWN
			dash_direction = facing
			return

	# Start a down smash in mid-air
	if Input.is_action_just_pressed("ui_down") and not is_on_floor() and not is_smashing:
		is_smashing = true
		velocity.x = 0
		velocity.y = SMASH_SPEED

	# While smashing, ignore jump and horizontal input
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
	# Add your impact effects here: screen shake, particles, sound, etc.
