extends CharacterBody2D

const SPEED = 60.0

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var direction = 1.0

func _ready():
	$StompArea.body_entered.connect(_on_stomp_area_body_entered)

func _physics_process(delta):
	if not is_on_floor():
		velocity.y += gravity * delta

	velocity.x = direction * SPEED
	move_and_slide()

	# Turn around when hitting a wall
	if is_on_wall():
		direction *= -1

func _on_stomp_area_body_entered(body):
	# Player is above the enemy's center, so it landed on top
	if body.is_in_group("player") and body.global_position.y < global_position.y:
		queue_free()
