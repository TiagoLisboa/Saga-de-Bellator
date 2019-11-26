extends MarginContainer

var vida_cheia = preload("res://vida1.png")
var vida_vazia = preload("res://vida2.png")

# Declare member variables here. Examples:
# var a = 2
# var b = "text"
onready var vidas = $HBoxContainer/Vida/Count.get_children()
onready var lose = $Lose
onready var win = $Win

# Called when the node enters the scene tree for the first time.
func _ready():
	self.remove_child($Lose)
	self.remove_child($Win)
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
func _on_player_lose_life(vida):
	vidas[vida].set_texture(vida_vazia)

func _on_player_die():
	self.add_child(lose)

func _on_player_win():
	self.add_child(win)

func _on_player_update_energia(energia):
	$HBoxContainer/Energia/TextureProgress.value = energia