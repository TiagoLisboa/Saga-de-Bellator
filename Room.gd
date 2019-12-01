extends RigidBody2D

var size
var doors = []
var d = 0
var activable = true
var deactivable = true
var mobs = []

func disable_shape():
	#$RoomArea/CollisionShape2D.shape = $CollisionShape2D.shape
	$CollisionShape2D.disabled = true

func add_door(x, y):
	doors.append(Vector2(x, y))
	
func add_mob(m):
	mobs.append(m)
	

func make_room(_pos, _size):
	position = _pos
	size = _size
	
	var s = RectangleShape2D.new()
	s.custom_solver_bias = 0.75
	s.extents = size
	$CollisionShape2D.shape = s
	
	s = RectangleShape2D.new()
	s.custom_solver_bias = 0.75
	s.extents = size - Vector2(64, 64)
	$RoomArea/CollisionShape2D.shape = s
	$RoomArea/CollisionShape2D.position = Vector2(16,16)
	
	connect("body_entered", self, "_close_doors")

func close_doors(pos):
	if activable:
		for m in mobs:
			$Mobs.add_child(m)
		activable = false
		get_tree().get_root().get_node("World").activate_doors(doors)

func open_doors():
	get_tree().get_root().get_node("World").deactivate_doors(doors)

func _on_player_update(pos):
	pass
	