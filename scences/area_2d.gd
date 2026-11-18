extends Area2D

@export var damage: int = 1
@export var damage_interval: float = 0.5

var _bodies := []
var _timer := 0.0

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body):
	if body.has_method("take_damage"):
		_bodies.append(body)
		body.take_damage(damage)
		_timer = 0.0

func _on_body_exited(body):
	_bodies.erase(body)

func _physics_process(delta):
	if _bodies.is_empty():
		return
	_timer += delta
	if _timer >= damage_interval:
		_timer = 0.0
		for b in _bodies:
			b.take_damage(damage)
