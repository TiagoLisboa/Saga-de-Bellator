extends Node2D

var MAX_SPEED = 500
var ACCELERATION = 2000
var motion = Vector2.ZERO
var speed = 200.0

var nav = null
var path = PoolVector2Array()
var goal = Vector2()

var active = false

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

# Called when the node enters the scene tree for the first time.
func _ready():
	set_process(false)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var move_distance = speed * delta
	_move_along_path(move_distance)
	#position=position+Vector2(5,0)

func _move_along_path(distance):
	var starting_point = position
	for i in range(path.size()):
		var distance_to_next = starting_point.distance_to(path[0])
		if distance <= distance_to_next and distance >= 0:
			position = starting_point.linear_interpolate(path[0], distance / distance_to_next)
			break
		elif distance < 0:
			position = path[0]
			set_process(false)
			break
		distance -= distance_to_next
		starting_point = path[0]
		path.remove(0)
	
func make_mob(_pos, new_nav):
	position = _pos
	nav = new_nav
	
	"""
	var s = RectangleShape2D.new()
	s.custom_solver_bias = 0.75
	s.extents = size
	$CollisionShape2D.shape = s
	"""
	
func update_path(new_goal):
	goal = new_goal
	path = nav.get_simple_path(position, goal)
	if path.size() == 0:
		return
	set_process(true)


