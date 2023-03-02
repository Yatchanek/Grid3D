extends Camera


var hidden_pillars = {} 

var previous_collisions = []
var current_collisions = []

var frame = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func _process(delta):
	frame += 1

	if frame % 20 == 0:
		current_collisions = []
		var state = get_world().direct_space_state
		var collision = state.intersect_ray(global_transform.origin, Globals.player.global_transform.origin + Vector3(0, 0.5,0))
		while check_collision(collision):
			var last_collider = collision.collider
			var last_pos = collision.position
			collision = state.intersect_ray(last_pos, Globals.player.global_transform.origin + Vector3(0, 0.5,0), [last_collider])
		for enemy in get_tree().get_nodes_in_group("Enemies"):
			collision = state.intersect_ray(global_transform.origin, enemy.global_transform.origin + Vector3(0, 0.5,0))
			while check_collision(collision):
				var last_collider = collision.collider
				var last_pos = collision.position
				collision = state.intersect_ray(last_pos, enemy.global_transform.origin + Vector3(0, 0.5,0), [last_collider])
		for pillar in hidden_pillars.keys():
			if !pillar in current_collisions:
				hidden_pillars[pillar].get_parent().make_opaque()
				hidden_pillars[pillar].get_parent().is_transparent = false
				hidden_pillars.erase(pillar)
	
		current_collisions = []
		frame = 0

func check_collision(collision):
	if collision and collision.collider.name == "PillarBody":
		var body = collision.collider.get_parent()
		body.make_transparent()
		body.is_transparent = true
		hidden_pillars[body.tile_id] = collision.collider
		current_collisions.append(body.tile_id)
		return true
	return false
