extends Spatial

var COLS = 3
var ROWS = 3

var enemy_scenes = [preload("res://Barbarian.tscn"), preload("res://Skeleton.tscn")]
var player_scene = preload("res://Player.tscn")

const TILE_SIZE = 2

onready var camera_pivot = $CameraPivot
onready var camera_gimbal = $CameraPivot/CameraGimbal
onready var camera = $CameraPivot/CameraGimbal/Camera

var turns_to_next_enemy : int = 4
var current_enemy : int = 0
var turn_camera : bool = false

func _input(event):
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == BUTTON_RIGHT:
			turn_camera = true
		elif !event.pressed and event.button_index == BUTTON_RIGHT:
			turn_camera = false
		elif event.pressed and event.button_index == BUTTON_WHEEL_UP:
			camera_gimbal.transform.origin.z -= 0.5
		elif event.pressed and event.button_index == BUTTON_WHEEL_DOWN:
			camera_gimbal.transform.origin.z += 0.5


	if event is InputEventMouseMotion:
		if turn_camera:
			camera_pivot.rotate_y(-event.relative.x * 0.005)
			#camera_gimbal.rotate_x(event.relative.y * 0.005)
			#camera_gimbal.rotation.x = clamp(camera_gimbal.rotation.x, -PI/4, PI/6)
			
	if event is InputEventKey:
		if event.pressed:
			match event.scancode:
				KEY_ESCAPE:
					get_tree().quit()
	
				KEY_ENTER:
					get_tree().reload_current_scene()
			
				KEY_Q:
					camera_gimbal.transform.origin.z = Globals.map.ROWS * TILE_SIZE / 2 + 3.5 * TILE_SIZE
					camera.look_at(camera_pivot.transform.origin, Vector3.UP)	
			
func _ready():
	randomize()



func create_world():
	var player = player_scene.instance()
	call_deferred("add_child", player)
	var points = $Tiles.a_star.get_points()
	var start_point = points[randi() % points.size()]
	while $Tiles.a_star.is_point_disabled(start_point):
		start_point = points[randi() % points.size()]
	player.transform.origin = $Tiles.a_star.get_point_position(start_point)
	player.occupied_tile = start_point
	player.rotate_y(PI)
	
	camera_pivot.transform.origin.x = (Globals.map.COLS * TILE_SIZE) / 2 - 0.5 * TILE_SIZE
	camera_gimbal.transform.origin.y = min(max(5, Globals.map.ROWS), 8)
	camera_pivot.transform.origin.z = (Globals.map.ROWS * TILE_SIZE) / 2 - 0.5 * TILE_SIZE
	camera_gimbal.transform.origin.z = Globals.map.ROWS * TILE_SIZE / 2 + 3.5 * TILE_SIZE
	camera.look_at(camera_pivot.transform.origin, Vector3.UP)

	for i in 2:
		spawn_enemy()	



func spawn_enemy():
	var enemy = enemy_scenes[randi() % enemy_scenes.size()].instance()
	var points = $Tiles.a_star.get_points()
	var start_point = points[randi() % points.size()]
	while $Tiles.a_star.is_point_disabled(start_point):
		start_point = points[randi() % points.size()]
	enemy.transform.origin = $Tiles.a_star.get_point_position(start_point)
	enemy.occupied_tile = start_point
	call_deferred("add_child", enemy)	


func _on_Enemy_move_ended():
	current_enemy += 1
	if current_enemy < Globals.map.enemies.size():
		if is_instance_valid(Globals.map.enemies[current_enemy]):
			Globals.map.enemies[current_enemy].seek_and_destroy()
		else:
			current_enemy += 1
			_on_Enemy_move_ended()
	else:
		Globals.player.can_take_action = true
		Globals.map.check_for_enemies_in_range()
		Globals.map.calculate_path(Globals.player.occupied_tile, Globals.map.hovered_tile_id, Globals.player)

func _on_Player_move_ended():
	Globals.player.can_take_action = false
	Globals.map.check_for_enemies_in_range()
	current_enemy = 0
	turns_to_next_enemy -= 1
	if Globals.map.enemies.size() > 0:
		Globals.map.enemies[current_enemy].seek_and_destroy()
	else:
		Globals.player.can_take_action = true
	if turns_to_next_enemy == 0:
		spawn_enemy()
		turns_to_next_enemy = 4
		
	
	
func _on_Tile_occupied(_id : int):
	$Tiles.set_occupied_tile(_id)


func _on_Character_moved(_id : int):
	$Tiles.release_occupied_tile(_id)
