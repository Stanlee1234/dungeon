extends CharacterBody2D

const SPEED = 75.0
const JUMP_VELOCITY = -200.0

var DEAD = false

@onready var sprite = $AnimatedSprite2D

func _physics_process(delta: float) -> void:
	if not DEAD:
		if not is_on_floor():
			velocity += get_gravity() * delta

		if Input.is_action_just_pressed("ui_up") and is_on_floor():
			velocity.y = JUMP_VELOCITY

		var direction := Input.get_axis("ui_left", "ui_right")
		if direction:
			velocity.x = direction * SPEED
			sprite.flip_h = direction < 0
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)

		_update_animations(direction)
		move_and_slide()

func _update_animations(direction):
	if not is_on_floor():
		sprite.play("jump")
	elif direction != 0:
		sprite.play("walk")
	else:
		sprite.play("idle")
		
func _die():
	if DEAD: 
		return
	DEAD = true
	
	set_physics_process(false) 
	call_deferred("_reload_game")

func _reload_game():
	await get_tree().create_timer(1).timeout
	get_tree().reload_current_scene()
