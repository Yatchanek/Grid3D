extends AnimationPlayer


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var elapsed_time : float = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	elapsed_time += delta
	if elapsed_time >= 0.125:
		elapsed_time = 0
		print(current_animation)
