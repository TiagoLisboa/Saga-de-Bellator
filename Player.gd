extends KinematicBody2D

class_name Player

signal player_update
signal player_lose_life
signal player_update_energia
signal player_die
signal player_win

var MAX_SPEED = 100
var ACCELERATION = 2000
var motion = Vector2.ZERO
var de = 0
var vida = 5
var energia = 1000

var blast = preload("res://PowerBlast.tscn")

func _process(delta):
	if Input.is_action_pressed("shift") and energia - 250*delta > 0:
		energia -= 250*delta
		MAX_SPEED = 200
	else:
		MAX_SPEED = 100
	energia += 100*delta
	if energia > 1000:
		energia = 1000
	else:
		emit_signal("player_update_energia", energia)
	
func _physics_process(delta):
	de += delta
	if de > .3:
		emit_signal("player_update", self.position)
		de = 0
	var axis = get_input_axis()
	if axis == Vector2.ZERO:
		apply_friction(ACCELERATION * delta)
	else:
		apply_movement(axis * ACCELERATION * delta)
	motion = move_and_slide(motion)
	
func get_input_axis():
	var axis = Vector2.ZERO
	axis.x = int(Input.is_action_pressed("right")) - int(Input.is_action_pressed("left"))
	axis.y = int(Input.is_action_pressed("down")) - int(Input.is_action_pressed("up"))
	if axis != Vector2.ZERO:
		$AnimatedSprite.play("move")
	else:
		$AnimatedSprite.play("idle")
	if axis.x < 0:
		$AnimatedSprite.flip_h = true
	if axis.x > 0:
		$AnimatedSprite.flip_h = false
	return axis.normalized()
	
func _input(event):
	if Input.is_action_just_pressed("mouse_click"):
		lancar_poder()

func lancar_poder():
	if energia - 300 > 0:
		var new_blast = blast.instance()
		new_blast.initialize((get_global_mouse_position() - global_position).normalized())
		new_blast.position = position
		energia -= 300
		emit_signal("player_update_energia", energia)
		add_child(new_blast)

func apply_friction(amount):
	if motion.length() > amount:
		motion -= motion.normalized() * amount
	else:
		motion = Vector2.ZERO

func apply_movement(acceleration):
	motion += acceleration
	motion = motion.clamped(MAX_SPEED)

func add_connection(s, e, f):
	connect(s, e, f)


func lose_life():
	if vida > 0:
		vida -= 1
		emit_signal("player_lose_life", self.vida)
	else:
		set_process_input(false)
		set_physics_process(false)
		emit_signal("player_die")

func win():
	set_process_input(false)
	set_physics_process(false)
	emit_signal("player_win")