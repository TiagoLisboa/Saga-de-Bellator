extends MarginContainer

var vida_cheia = preload("res://vida1.png")
var vida_vazia = preload("res://vida2.png")

# Declare member variables here. Examples:
# var a = 2
# var b = "text"
onready var vidas = $HBoxContainer/Vida/Count.get_children()
onready var color = $ColorRect
# Called when the node enters the scene tree for the first time.
func _ready():
	self.remove_child($ColorRect)
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
func _on_player_lose_life(vida):
	vidas[vida].set_texture(vida_vazia)

func _on_player_die():
	self.add_child(color)