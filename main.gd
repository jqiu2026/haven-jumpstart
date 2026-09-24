extends Node

@export var survive_time: float = 10.0
@export var ghost_spawn_interval: float = 20.0
@export var intro_text_duration: float = 2.5

var ghost_spawn_position: Vector2 = Vector2.ZERO

var time_remaining: float = 0.0
var spawn_timer: float = 0.0
var run_finished: bool = false

@onready var survive_label: Label = %SurviveLabel
@onready var timer_label: Label = %TimerLabel
@onready var ghost_template: Node = $Ghost

func _ready() -> void:
	time_remaining = survive_time
	_update_timer_label()
	survive_label.visible = true
	survive_label.modulate.a = 1.0
	get_tree().create_timer(intro_text_duration).timeout.connect(_hide_intro_text)
	ghost_spawn_position = ghost_template.global_position

func _process(delta: float) -> void:
	# Don't tick the timer or spawn ghosts while paused/dead
	if get_tree().paused or run_finished:
		return

	time_remaining = max(time_remaining - delta, 0.0)
	spawn_timer += delta
	_update_timer_label()

	if spawn_timer >= ghost_spawn_interval:
		spawn_timer -= ghost_spawn_interval
		_spawn_ghost()

	if time_remaining <= 0.0:
		run_finished = true
		_show_win_screen()

func _update_timer_label() -> void:
	var minutes := int(time_remaining) / 60
	var seconds := int(time_remaining) % 60
	timer_label.text = "%01d:%02d" % [minutes, seconds]

func _hide_intro_text() -> void:
	var tween := create_tween()
	tween.tween_property(survive_label, "modulate:a", 0.0, 1.0)

func _spawn_ghost() -> void:
	var new_ghost = ghost_template.duplicate()
	new_ghost.owner = get_tree().current_scene
	add_child(new_ghost)
	new_ghost.global_position = ghost_spawn_position

	new_ghost.player = %Player
	new_ghost.camera = get_tree().current_scene.find_child("Camera2D", true, false)
	new_ghost.red_overlay = %RedOverlay
	new_ghost.game_over_label = get_node("%GameOverLabel")

	var kill_zone: Area2D = new_ghost.get_node("AnimatedSprite2D/KillZone")
	if not kill_zone.body_entered.is_connected(new_ghost._on_kill_zone_body_entered):
		kill_zone.body_entered.connect(new_ghost._on_kill_zone_body_entered)

	print("New ghost spawned!")
	
func _show_win_screen() -> void:
	stop_all_audio()
	var game_over_label := get_node("%GameOverLabel") as Label
	game_over_label.text = "Congrats!"

	# Swap in a yellow copy of the same font/size/shadow, so the death
	# screen's red LabelSettings resource is left untouched.
	var win_settings := LabelSettings.new()
	if game_over_label.label_settings:
		win_settings.font = game_over_label.label_settings.font
		win_settings.font_size = game_over_label.label_settings.font_size
		win_settings.shadow_size = game_over_label.label_settings.shadow_size
		win_settings.shadow_color = game_over_label.label_settings.shadow_color
	win_settings.font_color = Color(1, 1, 0, 1) # yellow
	game_over_label.label_settings = win_settings

	game_over_label.visible = true
	
	get_tree().current_scene.stop_all_audio()
	get_tree().paused = true

func stop_all_audio(node: Node = self) -> void:
	if node is AudioStreamPlayer or node is AudioStreamPlayer2D or node is AudioStreamPlayer3D:
		node.stop()
	for child in node.get_children():
		stop_all_audio(child)
