extends CharacterBody2D

const SPEED = 60.0
const ATTACK_HIT_FRAME = 3

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var direction = 1.0
var health = 3
var is_attacking = false
var is_hurt = false
var is_dead = false

@onready var sprite = $AnimatedSprite2D
@onready var hitbox = $Hitbox
@onready var attack_range = $AttackRange

func _ready():
	add_to_group("enemy")
	sprite.frame_changed.connect(_on_frame_changed)
	sprite.animation_finished.connect(_on_animation_finished)

func take_damage(amount):
	if is_dead:
		return
	health -= amount
	is_attacking = false
	if health <= 0:
		is_dead = true
		hitbox.set_deferred("monitoring", false)
		attack_range.set_deferred("monitoring", false)
		sprite.play("death")
	else:
		is_hurt = true
		sprite.play("hurt")

func _physics_process(delta):
	if not is_on_floor():
		velocity.y += gravity * delta

	# Stand still while attacking, hurt or dead
	if is_attacking or is_hurt or is_dead:
		velocity.x = 0
		move_and_slide()
		return

	# Start an attack when the player is in range
	for body in attack_range.get_overlapping_bodies():
		if body.is_in_group("player"):
			is_attacking = true
			direction = 1.0 if body.global_position.x > global_position.x else -1.0
			sprite.flip_h = direction > 0
			sprite.play("attack")
			return

	# Otherwise patrol
	velocity.x = direction * SPEED
	move_and_slide()

	if is_on_wall():
		direction *= -1

	sprite.flip_h = direction > 0
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
	elif sprite.animation == "hurt":
		is_hurt = false
	elif sprite.animation == "die":
		queue_free()
