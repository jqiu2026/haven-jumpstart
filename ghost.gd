extends Area2D

@export var speed: float = 100.0
@export var audio_distance: float = 250.0  # Range where player hears sounds
@export var visual_distance: float = 125.0 #range where player sees effects

var player: Node2D = null
var is_lethal: bool = false

var loop_timer: float = 0.0
var half_duration: float = 0.0
var is_screeching: bool = false

@onready var animated_sprite = $AnimatedSprite2D
@onready var breathing_sfx = $BreathingSFX
@onready var screech_sfx = $ScreechSFX

var camera: Camera2D = null
var red_overlay: ColorRect = null
var game_over_label: Label = null

func _ready() -> void:
	if has_node("%Player"):
		player = get_node("%Player") as Node2D
	
	camera = get_tree().current_scene.find_child("Camera2D", true, false)
	
	if has_node("%RedOverlay"):
		red_overlay = get_node("%RedOverlay") as ColorRect
		print("Ghost connected to the Red Overlay successfully!")
	else:
		print("Ghost Warning: Could not find %RedOverlay in this scene tree layout.")

	if has_node("%GameOverLabel"):
		game_over_label = get_node("%GameOverLabel") as Label

	if screech_sfx.stream:
		half_duration = screech_sfx.stream.get_length() / 2.0

	await get_tree().create_timer(2.0).timeout
	is_lethal = true
	
	if red_overlay:
		red_overlay.self_modulate = Color(1, 1, 1, 1) # Solid White multiplier
		red_overlay.modulate = Color(1, 0, 0, 0)      # Red base, but 0% visible Alpha

func _process(delta: float) -> void:
	if player != null:
		var target_vector = player.global_position - global_position
		var distance = target_vector.length()
		
		# Standard Chase Movement
		if distance > 5.0:
			var direction = target_vector.normalized()
			var move = Vector2(direction.x * speed, direction.y * speed * 0.3) # slower to change vertically
			global_position += move * delta
			animated_sprite.flip_h = direction.x > 0
		
		# Distance and Audio Layering Checks
		if distance < audio_distance:
			# Calculate intensity percentage (0.0 at edge -> 1.0 touching player)
			var intensity = 1.0 - (distance / audio_distance)
			intensity = clamp(intensity, 0.0, 1.0)
			
			# Map intensity smoothly to decibels (faint far away, fully loud close up)
			screech_sfx.volume_db = lerp(-30.0, 0.0, intensity)
			breathing_sfx.pitch_scale = 1.0 + (intensity * 0.5) 
			
			# Handle the canon/overlapping layering loop
			is_screeching = true
			run_layered_screech_engine(delta)
		else:
			# Smoothly fade volume out and end the layering loop
			is_screeching = false
			screech_sfx.volume_db = lerp(screech_sfx.volume_db, -40.0, 6.0 * delta) # -80 is dead silent
			breathing_sfx.pitch_scale = 1.0

		# Visual Layering Checks (Triggers closer to the player)
		if distance < visual_distance:
			var visual_intensity = 1.0 - (distance / visual_distance)
			visual_intensity = clamp(visual_intensity, 0.0, 1.0)
			
			apply_screen_effects(visual_intensity, delta)
		else:
			# Clean up visual effects smoothly if the player is outside visual range
			if red_overlay:
				red_overlay.modulate.a = lerp(red_overlay.modulate.a, 0.0, 5.0 * delta)
			if camera:
				camera.offset = camera.offset.lerp(Vector2.ZERO, 5.0 * delta)

func run_layered_screech_engine(delta: float) -> void:
	if not is_screeching:
		return
		
	loop_timer += delta
	
	# If this is the very first time starting, or we hit the 50% finished mark:
	if loop_timer >= half_duration or not screech_sfx.playing:
		screech_sfx.play() # Fires a brand new layer overlaying the old one
		loop_timer = 0.0   # Reset clock to wait for the next 50% point

func apply_screen_effects(intensity: float, delta: float) -> void:
	# Faint Red flash intensifies (alpha modulation adjusted via opacity multiplier)
	if red_overlay:
		red_overlay.modulate.a = intensity * 0.7
		
	# Screen Shake / Wobble applied to camera offset
	if camera:
		var shake_amount = intensity * 7.0 
		camera.offset = Vector2(
			randf_range(-shake_amount, shake_amount),
			randf_range(-shake_amount, shake_amount)
		)

func _on_kill_zone_body_entered(body: Node2D) -> void:
	if is_lethal and body.is_in_group("Player"):
		print("Player caught! Triggering Game Over...")

		if game_over_label:
			game_over_label.visible = true
		else:
			print("CRITICAL GAME OVER - Player has been eliminated!")

		get_tree().current_scene.stop_all_audio()
		get_tree().paused = true
		await get_tree().create_timer(2.0, true).timeout
		get_tree().paused = false
		get_tree().reload_current_scene()
