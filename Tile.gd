extends Spatial


var id : int = 0
var x : int = 0
var y : int = 0
var move_cost : int = 0
var occupied : bool = false
var passable : bool = true

signal clicked
signal hovered
signal unhovered

func _ready():
	$mesh.get("material/0").set_shader_param("base_color", $mesh.mesh.surface_get_material(0).albedo_color)
	
	connect("clicked", get_parent(), "_on_Tile_clicked", [self.id])
	connect("hovered", get_parent(), "_on_Tile_hovered", [self.id])
	connect("unhovered", get_parent(), "_on_Tile_unhovered", [self.id])
	rotate_y(randi() % 4 * (PI / 2))
#$mesh.mesh.surface_get_material(1).set_shader_param("base_color", $mesh.mesh.surface_get_material(0).albedo_color)

func highlight(color : Color):
	$mesh.get("material/0").set_shader_param("mix_ratio", 1.0)	
	$mesh.get("material/0").set_shader_param("target_color", color)
	
func turn_off():
	$mesh.get("material/0").set_shader_param("mix_ratio", 0.0)

func _on_Area_mouse_entered():
	if !passable:
		Input.set_default_cursor_shape(Input.CURSOR_FORBIDDEN)
	else:
		Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)
		emit_signal("hovered")


func _on_Area_mouse_exited():
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)
	emit_signal("unhovered")

func _on_Area_input_event(_camera, event, _position, _normal, _shape_idx):
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == BUTTON_LEFT:
			emit_signal("clicked")
