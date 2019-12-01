extends Area2D

var direction

export var move_speed = 60

#var mob = preload("res://mob.tscn")

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

# Called when the node enters the scene tree for the first time.
func _ready():
	connect("body_entered", self, "_on_body_entered")
	set_as_toplevel(true)

	var audio_player = AudioStreamPlayer2D.new()
	self.add_child(audio_player)
	audio_player.stream = load("res://music/19522__musiclegends__retro-8-bit-sfx-sound-effects-pack/344303__musiclegends__explosion52.wav")
	audio_player.play()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	position += direction * move_speed * delta
	#print (position)

func initialize(_direction):
	direction = _direction
	rotation = direction.angle()

func _on_body_entered(body):
	if body.is_a_parent_of(self):
		return
	
	var enemy_hit = false
	if body is Mob:
		body.destroy()
		queue_free()
	
	print(body)
	queue_free()