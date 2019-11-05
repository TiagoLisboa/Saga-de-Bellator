extends KinematicBody2D

signal player_update

var MAX_SPEED = 100
var ACCELERATION = 2000
var motion = Vector2.ZERO
var de = 0

var blast = preload("res://PowerBlast.tscn")

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
	var new_blast = blast.instance()
	new_blast.initialize((get_global_mouse_position() - global_position).normalized())
	new_blast.position = position
	add_child(new_blast)

func apply_friction(amount):
	if motion.length() > amount:
		motion -= motion.normalized() * amount
	else:
		motion = Vector2.ZERO

func apply_movement(acceleration):
	motion += acceleration
	motion = motion.clamped(MAX_SPEED)

func add_connection(e):
	connect("player_update", e, "_on_player_update")
	