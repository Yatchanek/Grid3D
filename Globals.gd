extends Node

var player
var map
# Called when the node enters the scene tree for the first time.
func _ready():
	pass


func _on_Player_ready(_player):
	player = _player

func _on_Map_ready(_map):
	map = _map
