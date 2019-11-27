extends RigidBody2D

var size
var doors = []
var d = 0
var activable = true
var deactivable = true
var mobs

func disable_shape():
	#$RoomArea/CollisionShape2D.shape = $CollisionShape2D.shape
	$CollisionShape2D.disabled = true

func add_door(x, y):
	doors.append(Vector2(x, y))
	
func add_mob(m):
	$Mobs.add_child(m)
	mobs = $Mobs.get_children()

func make_room(_pos, _size):
	position = _pos
	size = _size
	
	var s = RectangleShape2D.new()
	s.custom_solver_bias = 0.75
	s.extents = size
	$CollisionShape2D.shape = s
	
	s = RectangleShape2D.new()
	s.custom_solver_bias = 0.75
	s.extents = size - Vector2(48, 48)
	$RoomArea/CollisionShape2D.shape = s
	$RoomArea/CollisionShape2D.position = Vector2(48,48)
	
	connect("body_entered", self, "_close_doors")

func close_doors(pos):
	if activable:
		activable = false
		get_tree().get_root().get_node("World").activate_doors(doors)

func open_doors():
	get_tree().get_root().get_node("World").deactivate_doors(doors)

func _on_player_update(pos):
	return
	if activable == true:
		activable = false
		var start = position - size + Vector2(32,32)
		var end = position + size - Vector2(32,32)
		if (pos >= start and pos <= end):
			get_tree().get_root().get_node("World").activate_doors(doors)
	elif deactivable == true:
		mobs = $Mobs.get_children()
		if len(mobs) == 0:
			deactivable = false
			get_tree().get_root().get_node("World").deactivate_doors(doors)
			
			