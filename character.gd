class_name Character
extends Spatial


var is_turning : bool = false
var is_turning_to_attack : bool = false
var is_moving : bool = false
var is_attacking : bool = false
var is_jumping : bool = false
var can_take_action : bool = true

var move_duration : float = 1.067 * 0.5
onready var anim_player = $Body/AnimationPlayer
var anim_player_2
var occupied_tile : int

var current_pos : Vector2
var grid_pos : Vector2

var path : PoolIntArray
var a_star : AStar

var target : Vector3

var max_moves : int
var moves_left : int

signal tile_occupied
signal tile_released
signal move_ended_partially
signal move_ended

func _ready():
	anim_player.play("Idle")
	set_physics_process(false)
	connect("tile_occupied", Globals.map, "_on_Tile_occupied")
	connect("tile_released", get_parent(), "_on_Character_moved")
	connect("ready", Globals.map, "_on_Entity_entered", [self])
	add_to_group("Actors")
	set_physics_process(false)

func _physics_process(delta):
	var target_basis : Basis
	var q_from = transform.basis.get_rotation_quat()
	if is_turning_to_attack:
		target_basis = transform.looking_at(target, Vector3.UP).basis			
	else:
		target_basis = transform.looking_at(a_star.get_point_position(path[0]), Vector3.UP).basis	
#	else:
#		target_basis = Basis.IDENTITY.rotated(Vector3.UP, PI)


	var q_to = target_basis.get_rotation_quat()
	transform.basis = Basis(q_from.slerp(q_to, delta * 10))
	if transform.basis.z.dot(target_basis.z) > 0.99:
		transform.basis = target_basis
		set_physics_process(false)
		if is_turning_to_attack:
			is_turning_to_attack = false
			anim_player.play("Attack(1h)")
			if self.name == "Player":
				anim_player_2.play("SwordSlash")
		else:
			is_turning = false
			anim_player.play("Walk")
			move_to(a_star.get_point_position(path[0]))
			
func jump():
	is_jumping = true
	move_duration = 0.8
	anim_player.play("Jump")

func attack(tile_id):
	if self.name == "Player":
		can_take_action = false
	is_attacking = true
	target = a_star.get_point_position(tile_id)
	if check_for_rotation(target):
		is_turning_to_attack = true
		set_physics_process(true)
	else:
		anim_player.play("Attack(1h)")
		if self.name == "Player":
			anim_player_2.play("SwordSlash")


func set_path(_path, _a_star):
	path = _path
	a_star = _a_star
	if path.size() == 0:
		emit_signal("tile_occupied", occupied_tile)
		return
	if path.size() > moves_left:
		path.resize(moves_left + 1)
	move_on_path()
	
func move_on_path():
	if path.size() > 1:
		path.remove(0)
		is_moving = true
		transform = transform.orthonormalized()
		if check_for_rotation(a_star.get_point_position(path[0])):
			anim_player.stop()
			is_turning = true
			set_physics_process(true)
		else:
			move_to(a_star.get_point_position(path[0]))
	else:
		occupied_tile = path[0]
		transform.origin = a_star.get_point_position(path[0])
		transform = transform.orthonormalized()
		is_moving = false
		is_turning = false
		anim_player.playback_speed = 1.0
		anim_player.play("Idle")
		path = []
		check_for_move_end()


func check_for_move_end():
	pass
		
func check_for_player():
	pass

func check_for_rotation(_target : Vector3):
	var dir = transform.origin.direction_to(_target)
	var dot = -transform.basis.z.dot(dir)
	if dot < 0.9:
		return true
	return false
	
func move_to(dest : Vector3):
	is_moving = true
	
	anim_player.playback_speed = 2.0
	anim_player.play("Walk")
	var tw = create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_LINEAR)
	tw.connect("finished", self, "path_move_done")
	tw.tween_property(self, "transform:origin", dest, move_duration * 0.85)


func path_move_done():
	moves_left -= 1
	move_on_path()

func path_turning_done():
	transform = transform.orthonormalized()
	move_to(a_star.get_point_position(path[0]))
		
	
func turning_done():
	is_turning = false
	transform = transform.orthonormalized()


func _on_AnimationPlayer_animation_finished(anim_name):
	match anim_name:
		"Attack(1h)":
			is_attacking = false
			anim_player.play("Idle")
			moves_left = 0
			check_for_move_end()
		"Jump":
			is_moving = false
			is_jumping = false
			move_duration = 1.067
			
		"Defeat":
			queue_free()
