extends Character
class_name Enemy


signal move_start
signal died
var dead : bool = false


# Called when the node enters the scene tree for the first time.
func _ready():
	max_moves = 3
	moves_left = max_moves
	rotate_y(PI)
	connect("move_start", Globals.map, "_on_Enemy_move")
	connect("move_ended", get_parent(), "_on_Enemy_move_ended")
	#connect("died", get_parent(), "_on_Enemy_died")
	connect("died", Globals.map, "_on_Enemy_died")
	add_to_group("Enemies")

func seek_and_destroy():
	if dead:
		return
	if check_for_player() and moves_left > 0:
		var target = Globals.player.occupied_tile
		attack(target)
	else:
		chase_player()
		
func check_for_player():
	var my_tile = Globals.map.tiles[occupied_tile]
	var neighbours = Globals.map.get_tile_neighbours(my_tile.x, my_tile.y)
	if Globals.player.occupied_tile in neighbours:
		return true
	return false

	
func check_if_player_nearby():
	chase_player()

func chase_player():
	var player_pos = Globals.player.occupied_tile
	var tile = Globals.map.tiles[player_pos]
	var neighbours = Globals.map.get_tile_neighbours(tile.x, tile.y)
	var target_pos = neighbours[randi() % neighbours.size()]
	while a_star.is_point_disabled(target_pos):
		target_pos = neighbours[randi() % neighbours.size()]
	
	var begin = occupied_tile
	emit_signal("move_start", occupied_tile, player_pos, self)


func check_for_move_end():
	if moves_left > 0 and check_for_player():
		attack(Globals.player.occupied_tile)
	else:
		moves_left = max_moves
		emit_signal("tile_occupied", occupied_tile)
		emit_signal("move_ended")

func _on_Area_area_entered(area):
	dead = true
	remove_from_group("Enemies")
	emit_signal("died", self)
	anim_player.play("Defeat")
