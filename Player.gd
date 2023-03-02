extends Character


func _input(event):
	if is_moving or is_turning or is_attacking:
		return
	if event is InputEventKey:
		if event.pressed and event.scancode == KEY_Z:
			jump()

func _ready():
	max_moves = 4
	moves_left = 4
	anim_player_2 = $AnimationPlayer
	connect("ready", Globals, "_on_Player_ready", [self])
	connect("ready", Globals.map, "_on_Player_ready")
	connect("move_ended_partially", Globals.map, "_on_Player_move_ended")
	connect("move_ended", get_parent(), "_on_Player_move_ended")

func check_for_move_end():
	if moves_left > 0:
		emit_signal("move_ended_partially")
	else:
		moves_left = max_moves
		can_take_action = false
		emit_signal("tile_occupied", occupied_tile)
		emit_signal("move_ended")
		

func check_for_enemy():
	pass
