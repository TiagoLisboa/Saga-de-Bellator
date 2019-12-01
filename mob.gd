extends KinematicBody2D

class_name Mob

var MAX_SPEED = 50
var ACCELERATION = 2000
var motion = Vector2.ZERO
var speed = 500.0
var axis = Vector2.ZERO

var nav = null
var path = PoolVector2Array()
var goal = Vector2()

var active = null
var refresh = false
# Declare member variables here. Examples:
# var a = 2
# var b = "text"

# Called when the node enters the scene tree for the first time.
func _ready():
	set_process(false)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if not active == null:
		if $MobArea.overlaps_body(active):
			$AnimatedSprite.play("attack")
			yield($AnimatedSprite, 'animation_finished')
		else:
			if path.size() > 0:
				$AnimatedSprite.play("move")
				var move_distance = speed * delta
				_move_along_path(move_distance, delta)
				#position=position+Vector2(5,0)
				motion = move_and_slide(motion)
			else:
				$AnimatedSprite.play("idle")
			update_path(active.position)
	else:
		$AnimatedSprite.play("idle")

func _move_along_path(distance, delta):
	var starting_point = position
	while path.size() > 0:
		var distance_to_next = starting_point.distance_to(path[0])
		if distance <= distance_to_next:
			var old_pos = position
			var direction = path[0] - old_pos
			axis = direction.normalized()
			if axis == Vector2.ZERO:
				apply_friction(ACCELERATION * delta)
			else:
				apply_movement(axis * ACCELERATION * delta)
			if axis.x < 0:
				$AnimatedSprite.flip_h = true
			if axis.x > 0:
				$AnimatedSprite.flip_h = false
			#return
			"""
		elif distance < 0:
			axis = path[0]
			axis = axis.normalized()
			if axis == Vector2.ZERO:
				apply_friction(ACCELERATION * delta)
			else:
				apply_movement(axis * ACCELERATION * delta)
			motion = move_and_slide(motion)
			set_process(false)
			break
			"""
		axis = Vector2.ZERO
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

func start_following(body):
	active = body
	update_path(active.position)
	set_process(true)

func stop_following():
	active = null
	set_process(false)

func apply_friction(amount):
	if motion.length() > amount:
		motion -= motion.normalized() * amount
	else:
		motion = Vector2.ZERO

func apply_movement(acceleration):
	motion += acceleration
	motion = motion.clamped(MAX_SPEED)


func destroy():
	if len(get_parent().get_children()) == 1:
		get_parent().get_parent().open_doors()
	queue_free()

func _on_view(body):
	start_following(body)

func _off_view(body):
	stop_following()

func _on_AnimatedSprite_animation_finished():
	if $AnimatedSprite.animation == "attack" and $MobArea.overlaps_body(active):
		active.lose_life()
