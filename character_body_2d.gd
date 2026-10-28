extends CharacterBody2D

const SPEED = 60.0
const ATTACK_HIT_FRAME = 3

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var direction = 1.0
var is_attacking = false

@onready var sprite = $AnimatedSprite2D
@onready var hitbox = $Hitbox
@onready var attack_range = $AttackRange

func _ready():
	sprite.frame_changed.connect(_on_frame_changed)
	sprite.animation_finished.connect(_on_animation_finished)

func _physics_process(delta):
	if not is_on_floor():
		velocity.y += gravity * delta

	# Stand still while attacking
	if is_attacking:
		velocity.x = 0
		move_and_slide()
		return

	# Start an attack when the player is in range
	for body in attack_range.get_overlapping_bodies():
		if body.is_in_group("player"):
			is_attacking = true
			direction = 1.0 if body.global_position.x > global_position.x else -1.0
			sprite.flip_h = direction < 0
			sprite.play("attack")
			return

	# Otherwise patrol
	velocity.x = direction * SPEED
	move_and_slide()

	if is_on_wall():
		direction *= -1

	sprite.flip_h = direction < 0
	sprite.play("run")

# The damage lands on one frame of the attack animation
func _on_frame_changed():
	if sprite.animation == "attack" and sprite.frame == ATTACK_HIT_FRAME:
		for body in hitbox.get_overlapping_bodies():
			if body.is_in_group("player"):
				body.take_damage(1)

func _on_animation_finished():
	if sprite.animation == "attack":
		is_attacking = false
