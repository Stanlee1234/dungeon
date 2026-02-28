extends CharacterBody2D


const SPEED = 100.0
const JUMP_VELOCITY = -200.0

var DEAD = false

func _physics_process(delta: float) -> void:
	if not DEAD:
		# Add the gravity.
		if not is_on_floor():
			velocity += get_gravity() * delta

		# Handle jump.
		if Input.is_action_just_pressed("ui_accept") and is_on_floor():
			velocity.y = JUMP_VELOCITY

		# Get the input direction and handle the movement/deceleration.
		# As good practice, you should replace UI actions with custom gameplay actions.
		var direction := Input.get_axis("ui_left", "ui_right")
		if direction:
			velocity.x = direction * SPEED
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)

		move_and_slide()
		
func _die():
	if DEAD: 
		return
	DEAD = true
	
	set_physics_process(false) 
	get_tree().paused = false
	call_deferred("_reload_game")

func _reload_game():
	await get_tree().create_timer(1).timeout
	get_tree().reload_current_scene()
