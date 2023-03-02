extends Spatial


var tile_scene = preload("res://Tile2.tscn")
var pillar_scene = preload("res://Pillar.tscn")
var wall_scene = preload("res://Wall.tscn")
var corner_scene = preload("res://WallCorner.tscn")

var COLS = 7
var ROWS = 7
const TILE_SIZE = 2

var tiles = {}
var occupied_tiles = []
var enemies = []
var enemies_in_range = []
var a_star = AStar.new()
var hovered_tile : Spatial
var hovered_tile_id : int
var path_to_show : Array

signal board_created

func _ready():
	randomize()
	connect("ready", Globals, "_on_Map_ready", [self])
	COLS = randi() % 8 + 8
	ROWS = randi() % 8 + 8

	create_world()

func create_world():
	for x in COLS:
		for y in ROWS:
			var tile = tile_scene.instance()
			tile.transform.origin = Vector3(TILE_SIZE * x, 0, TILE_SIZE * y)
			tile.id = cantor_function(x, y)
			tile.x = x
			tile.y = y
			tiles[tile.id] = tile
			if x == 0 and y == 0:
				var corner = corner_scene.instance()
				corner.transform.origin = Vector3(TILE_SIZE * x, 0, TILE_SIZE * y)
				corner.rotate_y(PI / 2)
				call_deferred("add_child", corner)
				tile.passable = false
			if x == 0 and y == ROWS - 1:
				var corner = corner_scene.instance()
				corner.transform.origin = Vector3(TILE_SIZE * x, 0, TILE_SIZE * y)
				corner.rotate_y(PI)
				call_deferred("add_child", corner)
				tile.passable = false
			if x == COLS - 1 and y == 0:
				var corner = corner_scene.instance()
				corner.transform.origin = Vector3(TILE_SIZE * x, 0, TILE_SIZE * y)
				call_deferred("add_child", corner)
				tile.passable = false
			if x == COLS - 1 and y == ROWS - 1:
				var corner = corner_scene.instance()
				corner.transform.origin = Vector3(TILE_SIZE * x, 0, TILE_SIZE * y)
				corner.rotate_y(-PI/2)
				call_deferred("add_child", corner)
				tile.passable = false			
			if (y == 0 or y == ROWS - 1) and (x > 0 and x < COLS - 1):
				var wall = wall_scene.instance()
				#var wall_2 = wall_scene.instance()
				wall.transform.origin = Vector3(TILE_SIZE * x, 0, TILE_SIZE * y)
				#wall_2.transform.origin = Vector3(TILE_SIZE * x, 0, TILE_SIZE * (ROWS - 1))
				call_deferred("add_child", wall)
				tile.passable = false
				#call_deferred("add_child", wall_2)				
			if (x == 0 or x == COLS - 1) and (y > 0 and y < ROWS - 1):
				var wall = wall_scene.instance()
				#var wall_2 = wall_scene.instance()
				wall.transform.origin = Vector3(TILE_SIZE * x, 0, TILE_SIZE * y)
				wall.rotate_y(PI/2)
				#wall_2.transform.origin = Vector3(TILE_SIZE * x, 0, TILE_SIZE * (ROWS - 1))
				call_deferred("add_child", wall)
				tile.passable = false				
			if randf() < 0.1 and x > 0 and x < COLS - 1 and y > 0 and y < ROWS - 1:
				var pillar = pillar_scene.instance()
				pillar.tile_id = tile.id
				pillar.transform.origin = tile.transform.origin
				tile.passable = false
				call_deferred("add_child", pillar)
			add_child(tile)
			a_star.add_point(tile.id, tile.transform.origin + Vector3(0, 0.1, 0), 1)
			a_star.set_point_disabled(tile.id, !tile.passable)
	#for x in COLS:

	connect_points()

func connect_points():
	for tile in get_children():
		var neighbours = get_tile_neighbours(tile.x, tile.y)
		for neighbour in neighbours:		
			if !a_star.are_points_connected(tile.id, neighbour):
				a_star.connect_points(tile.id, neighbour)
	
	yield(get_tree().create_timer(0.1), "timeout")
	emit_signal("board_created")
	
func get_tile_neighbours(_x : int, _y : int):
	var neighbours = []
	for dx in [-1, 0, 1]:
		for dy in [-1, 0, 1]:
			if _x + dx < 0 or _x + dx >= COLS or \
			_y + dy < 0 or _y + dy >= ROWS or \
			(dy != 0 and dx != 0) or \
			(dx == 0 and dy == 0):
				continue
			else:
				neighbours.append(int(cantor_function(_x + dx, _y + dy)))
	return neighbours
	
func calculate_path(_start, _end, _entity):
	release_occupied_tile(_start)
	path_to_show = Array(a_star.get_id_path(_start, _end))

	if _entity.name == "Player":
		if path_to_show.size() == 0:
			if hovered_tile_id in enemies_in_range:
				Input.set_default_cursor_shape(Input.CURSOR_MOVE)
			else:
				Input.set_default_cursor_shape(Input.CURSOR_FORBIDDEN)
		if path_to_show.size() == 1:
			turn_off_tiles()

func get_player_neighbouring_tiles():
	var player_tile = tiles[Globals.player.occupied_tile]
	var neighbours = get_tile_neighbours(player_tile.x, player_tile.y)
	return neighbours

func check_for_enemies_in_range():
	enemies_in_range = []
	var neighbours = get_player_neighbouring_tiles()
	for enemy in get_tree().get_nodes_in_group("Enemies"):
		if enemy.occupied_tile in neighbours:
			enemies_in_range.append(enemy.occupied_tile)

func check_move(_id : int):
	if _id in occupied_tiles:
		var enemy_tile = tiles[_id]
		if Globals.player.occupied_tile in get_tile_neighbours(enemy_tile.x, enemy_tile.y) and Globals.player.moves_left > 0:
			
			Globals.player.attack(_id)
			return
			
	if tiles[_id].passable == false or path_to_show.size() == 0:
		return
	var begin = Globals.player.occupied_tile

	if !begin == _id:
		turn_off_tiles()
		Globals.player.set_path(path_to_show, a_star)

func set_occupied_tile(_id : int):
	a_star.set_point_disabled(_id, true)
	occupied_tiles.append(_id)
	
func release_occupied_tile(_id : int):
	a_star.set_point_disabled(_id, false)
	occupied_tiles.erase(_id)

func turn_off_tiles():
	for id in path_to_show:
		tiles[id].turn_off()
		
func highlight_tiles():
	var i = 0
	var color = Color(0, 0.85, 0)
	for id in path_to_show:
		if i > Globals.player.moves_left:
			color = Color(0.85, 0, 0)
		tiles[id].highlight(color)
		i += 1
		
func cantor_function(x : int, y: int):
	return 0.5 * (x + y) * (x + y + 1) + y	
	
func depair_cantor_function(z : float):
	var t = floor((sqrt(8 * z + 1) - 1) * 0.5)
	var y = z - t * (t + 1) / 2
	var x = t * (t + 3) / 2 - z
	return Vector2(x, y) 
	
func _on_Player_moved():
	turn_off_tiles()

func _on_Tile_hovered(_id):
	if !Globals.player:
		return
	hovered_tile = tiles[_id]			
	hovered_tile_id = _id
	if !Globals.player.is_moving and Globals.player.can_take_action:
		turn_off_tiles()
		calculate_path(Globals.player.occupied_tile, hovered_tile_id, Globals.player)
		if !path_to_show.size() <= 1:
			highlight_tiles()

func _on_Player_move_ended():
	turn_off_tiles()
	check_for_enemies_in_range()
	calculate_path(Globals.player.occupied_tile, hovered_tile_id, Globals.player)
	if !path_to_show.size() <= 1:
		highlight_tiles()	
	
func _on_Tile_unhovered(_id):
	pass

func _on_Tile_occupied(_id):
	path_to_show.resize(0)
	set_occupied_tile(_id)
	
func _on_Tile_clicked(_id : int):
	if Globals.player.is_moving or !Globals.player.can_take_action:
		return
	check_move(_id)

func _on_Enemy_move(_start : int, _target : int, _enemy : Enemy):
	release_occupied_tile(Globals.player.occupied_tile)
	calculate_path(_start, _target, _enemy)
	set_occupied_tile(Globals.player.occupied_tile)
	if path_to_show.size() > 0:
		path_to_show.remove(path_to_show.size() - 1)
		_enemy.set_path(path_to_show, a_star)
	else:
		_enemy.emit_signal("move_ended")

func _on_Entity_entered(_entity):
	_entity.a_star = a_star
	_entity.occupied_tile = a_star.get_closest_point(_entity.transform.origin)
	set_occupied_tile(_entity.occupied_tile)
	if _entity is Enemy:
		enemies.append(_entity)
		if _entity.occupied_tile in get_player_neighbouring_tiles():
			enemies_in_range.append(_entity)
	
func _on_Enemy_died(_enemy : Enemy):
	enemies.erase(_enemy)
	if _enemy in enemies_in_range:
		enemies_in_range.erase(_enemy)
	release_occupied_tile(_enemy.occupied_tile)

func _on_Player_ready():
	check_if_trapped()
	check_for_enemies_in_range()
	
func check_if_trapped():
	var neighbours = get_player_neighbouring_tiles()
	var trapped = true
	for neighbour in neighbours:
		if tiles[int(neighbour)].passable:
			trapped = false
			break
	if trapped:
		var neighbour = neighbours[randi() % neighbours.size()]
		
		tiles[int(neighbour)].passable = true
		var mesh_node = tiles[int(neighbour)].get_node("mesh")
		mesh_node.get("material/0").set_shader_param("base_color", mesh_node.mesh.surface_get_material(0).albedo_color)
