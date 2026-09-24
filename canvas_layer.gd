extends CanvasLayer

@onready var color_rect: ColorRect = $ColorRect

@export var player: CharacterBody2D
@export var camera: Camera2D

func _process(_delta: float) -> void:
	if player and camera:
		# Get the player's position relative to the camera's viewport
		var screen_pos = player.get_global_transform_with_canvas().origin
		
		# Get the current active size of the game window
		var viewport_size = get_viewport().get_visible_rect().size
		
		#Normalize the coordinates to a 0.0 -> 1.0 scale for the shader
		var normalized_pos = screen_pos / viewport_size
		
		# Feed the live position into the shader
		color_rect.material.set_shader_parameter("player_screen_pos", normalized_pos)
