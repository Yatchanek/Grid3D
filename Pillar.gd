extends Spatial


var tile_id : int
var is_transparent : bool = false
onready var mesh = $mesh


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func make_transparent():
	mesh.get("material/0").set_shader_param("transparency", 0.10)
	mesh.get("material/1").set_shader_param("transparency", 0.25)
	
func make_opaque():
	mesh.get("material/0").set_shader_param("transparency", 1.0)
	mesh.get("material/1").set_shader_param("transparency", 1.0)
