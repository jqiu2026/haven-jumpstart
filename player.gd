extends CharacterBody2D

@onready var _animation_sprite = $AnimatedSprite2D


@onready var footsteps_sfx = $FootstepsSFX

# Adjust these to fit your audio track's native loudness
@export var normal_volume: float = 0.0      # Full volume when walking
@export var silent_volume: float = -80.0    # Absolute silence when standing still
@export var fade_speed: float = 15.0        # Higher numbers mean a faster fade out


const SPEED = 150.0
const JUMP_VELOCITY = -300.0


func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() / 1.6 * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_axis("left", "right")
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide() 
	
	if velocity.length() > 10.0: # Using 10.0 avoids minor stick drift issues
		# Ensure the track is playing if it somehow stopped
		if not footsteps_sfx.playing:
			footsteps_sfx.play()
			
		# Smoothly blend the volume up to normal walking volume
		footsteps_sfx.volume_db = lerp(footsteps_sfx.volume_db, normal_volume, fade_speed * delta)
	else:
		# Smoothly blend the volume down to dead silence quickly
		footsteps_sfx.volume_db = lerp(footsteps_sfx.volume_db, silent_volume, fade_speed * delta)
