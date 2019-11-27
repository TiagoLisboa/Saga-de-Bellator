extends RigidBody2D

var size
var doors = []
var d = 0

func add_door(x, y):
	doors.append(Vector2(x, y))
	
func add_mob(m):
	$Mobs.add_child(m)

func make_room(_pos, _size):
	position = _pos
	size = _size
	
	var s = RectangleShape2D.new()
	s.custom_solver_bias = 0.75
	s.extents = size
	$CollisionShape2D.shape = s
	
func _on_player_update(pos):
	return
	var start = position - size + Vector2(32,32)
	var end = position + size - Vector2(32,32)
	if (pos >= start and pos <= end):
		for m in $Mobs.get_children():
			m.update_path(pos)
	else:
		for m in $Mobs.get_children():
			m.stop_following()
			
			