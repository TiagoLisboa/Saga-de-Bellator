extends Area2D

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

onready var mob = get_parent()
# Called when the node enters the scene tree for the first time.
func _ready():
	connect('body_entered', self, '_on_body_entered')
	connect("body_exited", self, "_on_body_exited")

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func _on_body_entered(body):
	if body is Player:
		mob._on_view(body)

func _on_body_exited(body):
	if body is Player:
		mob._off_view(body)