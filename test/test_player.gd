extends CharacterBody2D

signal smash_landed(position)
signal health_changed(new_health)
signal keys_changed(count)

const SPEED = 200.0
const JUMP_VELOCITY = -350.0
const MAX_JUMPS = 2
const SMASH_SPEED = 900.0

const DASH_SPEED = 350.0
const DASH_DURATION = 0.2
const DASH_COOLDOWN = 0.4

# Wall jump settings
const WALL_JUMP_PUSH = 200.0       # how hard you're pushed away from the wall
const WALL_JUMP_LOCK_TIME = 0.15   # seconds that left/right input is ignored after a wall jump

# Crystal dash settings (hold the dash button on a crystal block)
const CRYSTAL_CHARGE_TIME = 0.7    # seconds you must hold the button before it's ready
const CRYSTAL_SPEED = 600.0        # launch speed
const CRYSTAL_MAX_TIME = 1.5       # the dash stops after this long even if no wall is hit

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var jumps_left = MAX_JUMPS
var is_smashing = false

var is_dashing = false
var dash_timer = 0.0
var dash_cooldown_timer = 0.0
var dash_vector = Vector2.RIGHT
var facing = 1.0
var can_air_dash = true

var wall_jump_lock = 0.0

var is_crystal_charging = false
var crystal_charge_time := 0.0
var crystal_normal := Vector2.ZERO
var is_crystal_dashing = false
var crystal_dash_timer = 0.0
var crystal_dir := Vector2.RIGHT

@export var max_health: int = 5
var health: int = max_health
var invincible = false

var keys: int = 0

var is_attacking = false
var hit_done = false

# Where the player goes when pressing R. Starts as the level's start position.
var spawn_point: Vector2

# Remembers which missing tile data names we've already warned about
var _missing_layer_warned := {}

@onready var sprite = $AnimatedSprite2D
@onready var hitbox_shape = $AttackHitbox/CollisionShape2D
@onready var hitbox_base_x = hitbox_shape.position.x

func _ready():
	add_to_group("player")
	spawn_point = global_position

func _physics_process(delta):
	if dash_cooldown_timer > 0:
		dash_cooldown_timer -= delta

	# Active dash: no gravity, fixed velocity along the dash direction
	if is_dashing:
		dash_timer -= delta
		velocity = dash_vector * DASH_SPEED
		if dash_timer <= 0:
			is_dashing = false
			velocity.y = 0
		move_and_slide()
		return

	# Crystal dash: launching (no gravity, stops when it hits a wall)
	if is_crystal_dashing:
		crystal_dash_timer -= delta
		velocity = crystal_dir * CRYSTAL_SPEED
		move_and_slide()
		var hit_wall: bool = is_on_wall() and get_wall_normal().dot(crystal_dir) < -0.5
		if crystal_dash_timer <= 0 or hit_wall:
			is_crystal_dashing = false
			velocity = Vector2.ZERO
		return

	# Crystal dash: charging (frozen in place while the dash button is held)
	if is_crystal_charging:
		crystal_charge_time += delta
		velocity = Vector2.ZERO
		if not Input.is_action_pressed("dash"):
			is_crystal_charging = false
			if crystal_charge_time >= CRYSTAL_CHARGE_TIME:
				_start_crystal_dash()
			else:
				_try_start_dash()  # quick tap: do a normal dash instead
		move_and_slide()
		return

	# Pressing dash while touching a crystal tile starts charging
	if Input.is_action_just_pressed("dash") and not is_smashing:
		var n := _get_crystal_normal()
		if n != Vector2.ZERO:
			is_crystal_charging = true
			crystal_charge_time = 0.0
			crystal_normal = n
			velocity = Vector2.ZERO
			return

	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		jumps_left = MAX_JUMPS
		can_air_dash = true
		if is_smashing:
			_on_smash_land()

	# Normal dash (always horizontal, in the direction you're facing)
	if Input.is_action_just_pressed("dash") and _try_start_dash():
		return

	# Down smash
	if Input.is_action_just_pressed("ui_down") and not is_on_floor() and not is_smashing:
		is_smashing = true
		velocity.x = 0
		velocity.y = SMASH_SPEED

	# While smashing, ignore jump and horizontal input
	if is_smashing:
		move_and_slide()
		return

	# Are we touching a wall made of wall-jumpable tiles?
	var wall_normal := Vector2.ZERO
	if not is_on_floor() and is_on_wall():
		wall_normal = _get_wall_jump_normal()

	# Jump: wall jump (space bar only) first, then normal / double jump
	if Input.is_action_just_pressed("wall_jump") and wall_normal != Vector2.ZERO:
		velocity.y = JUMP_VELOCITY
		velocity.x = wall_normal.x * WALL_JUMP_PUSH
		wall_jump_lock = WALL_JUMP_LOCK_TIME
		facing = sign(wall_normal.x)
		jumps_left = MAX_JUMPS - 1  # the wall jump counts as your first jump, so one air jump is ready
	elif Input.is_action_just_pressed("ui_accept") and jumps_left > 0:
		velocity.y = JUMP_VELOCITY
		jumps_left -= 1

	# Left/right movement (briefly disabled right after a wall jump)
	if wall_jump_lock > 0:
		wall_jump_lock -= delta
	else:
		var direction = Input.get_axis("ui_left", "ui_right")
		if direction != 0:
			facing = sign(direction)
		velocity.x = direction * SPEED

	move_and_slide()

# Starts a normal dash if allowed. Returns true if it started.
func _try_start_dash() -> bool:
	if dash_cooldown_timer > 0 or is_smashing:
		return false
	if not is_on_floor() and not can_air_dash:
		return false

	if not is_on_floor():
		can_air_dash = false

	dash_vector = Vector2(facing, 0)
	is_dashing = true
	dash_timer = DASH_DURATION
	dash_cooldown_timer = DASH_COOLDOWN
	return true

# True if the tile at these coordinates has the given custom data flag set.
# Warns once (instead of erroring) if the TileSet has no custom data layer with that name.
func _tile_has_flag(tilemap: TileMapLayer, coords: Vector2i, flag: String) -> bool:
	var data := tilemap.get_cell_tile_data(coords)
	if data == null:
		return false

	if tilemap.tile_set.get_custom_data_layer_by_name(flag) == -1:
		if not _missing_layer_warned.has(flag):
			_missing_layer_warned[flag] = true
			push_warning("TileSet has no custom data layer named '%s'" % flag)
		return false

	return bool(data.get_custom_data(flag))

# Returns the wall's normal if we're touching a tile marked wall_jump, otherwise Vector2.ZERO
func _get_wall_jump_normal() -> Vector2:
	for i in get_slide_collision_count():
		var col := get_slide_collision(i)
		var normal := col.get_normal()
		if abs(normal.x) < 0.9:
			continue  # floor or ceiling, not a wall

		var tilemap := col.get_collider() as TileMapLayer
		if tilemap == null:
			continue

		# Find the tile by looking just inside the wall at the point we touched it
		var probe := col.get_position() - normal * 2.0
		var coords := tilemap.local_to_map(tilemap.to_local(probe))

		if _tile_has_flag(tilemap, coords, "wall_jump"):
			return normal
	return Vector2.ZERO

# Returns the surface normal if we're standing on or touching a tile marked crystal_dash
func _get_crystal_normal() -> Vector2:
	for i in get_slide_collision_count():
		var col := get_slide_collision(i)
		var normal := col.get_normal()
		if normal.y > 0.7:
			continue  # ceiling

		var tilemap := col.get_collider() as TileMapLayer
		if tilemap == null:
			continue

		var probe := col.get_position() - normal * 2.0
		var coords := tilemap.local_to_map(tilemap.to_local(probe))

		if _tile_has_flag(tilemap, coords, "crystal_dash"):
			return normal
	return Vector2.ZERO

func _start_crystal_dash() -> void:
	var dir_x := Input.get_axis("ui_left", "ui_right")
	if abs(crystal_normal.x) > 0.9:
		dir_x = sign(crystal_normal.x)  # charged on a wall: launch away from it
	elif dir_x == 0:
		dir_x = facing                  # charged on the floor: launch where you hold, or where you face

	crystal_dir = Vector2(sign(dir_x), 0)
	facing = sign(dir_x)
	is_crystal_dashing = true
	crystal_dash_timer = CRYSTAL_MAX_TIME

func _on_smash_land():
	is_smashing = false
	smash_landed.emit(global_position)
	# Add your impact effects here: screen shake, particles, sound, etc.

# Called by checkpoints when the player touches them
func set_checkpoint(pos: Vector2) -> void:
	spawn_point = pos

func respawn() -> void:
	global_position = spawn_point
	velocity = Vector2.ZERO
	is_dashing = false
	is_smashing = false
	is_crystal_charging = false
	is_crystal_dashing = false
	jumps_left = MAX_JUMPS
	can_air_dash = true
	dash_cooldown_timer = 0.0
	wall_jump_lock = 0.0

func add_key() -> void:
	keys += 1
	keys_changed.emit(keys)

func take_damage(amount):
	if invincible:
		return
	invincible = true
	health = clamp(health - amount, 0, max_health)
	health_changed.emit(health)

	if health <= 0:
		get_tree().reload_current_scene.call_deferred()
		return

	# Flash red and stay immune for 1 second
	modulate = Color(1, 0.4, 0.4)
	await get_tree().create_timer(1.0).timeout
	modulate = Color.WHITE
	invincible = false

func _input(event):
	if event.is_action_pressed("respawn"):
		respawn()

	if event.is_action_pressed("attack") and not is_attacking and not is_crystal_charging and not is_crystal_dashing:
		is_attacking = true
		hit_done = false
		sprite.play("attack")
		await sprite.animation_finished
		is_attacking = false

func _process(_delta):
	# Face the direction she is moving, and mirror the sword hitbox with her
	sprite.flip_h = facing < 0
	var side = 1.0 if facing >= 0 else -1.0
	hitbox_shape.position.x = sprite.position.x + (hitbox_base_x - sprite.position.x) * side

	# Tint the sprite while using the crystal dash
	if is_crystal_charging:
		var charged: bool = crystal_charge_time >= CRYSTAL_CHARGE_TIME
		sprite.modulate = Color(0.3, 1, 1) if charged else Color(0.7, 0.9, 1)
	elif is_crystal_dashing:
		sprite.modulate = Color(0.4, 1, 1)
	else:
		sprite.modulate = Color.WHITE

	# Don't override the attack animation while swinging
	if is_attacking:
		# The sword lands on one frame of the swing
		if sprite.animation == "attack" and sprite.frame == 6 and not hit_done:
			hit_done = true

			for body in $AttackHitbox.get_overlapping_bodies():
				if body.is_in_group("enemy"):
					body.take_damage(1)
		return

	# Optional: play a crystal animation if you made one
	if (is_crystal_charging or is_crystal_dashing) and sprite.sprite_frames.has_animation("crystal"):
		sprite.play("crystal")
		return

	# Optional: play a dash animation if you made one
	if is_dashing and sprite.sprite_frames.has_animation("dash"):
		sprite.play("dash")
		return

	if not is_on_floor():
		sprite.play("jump")
	elif abs(velocity.x) > 10:
		sprite.play("run")
	else:
		sprite.play("idle")
