extends Node2D

var Room = preload("res://Room.tscn")

var tile_size = 32
var num_rooms = 50
var min_size = 5
var max_size = 10
var hspread = 400
var cull = .5

var Player = preload("res://Player.tscn")
var blast = preload("res://PowerBlast.tscn")

var player = null
var dead = false
var start_room = null
var end_room = null

var mob = preload("res://mob.tscn")

var min_mobs = 3
var max_mobs = 7
onready var nav = $Navigation2D

var visited = TileMap.new()

onready var Map = $Navigation2D/TileMap


var path # AStar pathfinding obj

func _on_player_die():
	dead = true
	
func _ready():
	randomize()
	yield(make_rooms(), 'completed')
	make_map()
	place_things()
	
	for r in $Rooms.get_children():
		r.get_node("CollisionShape2D").disabled = true
	player = Player.instance()
	add_child(player)
	player.position = start_room.position
	for r in $Rooms.get_children():
		player.add_connection("player_update", r, "_on_player_update")
	player.add_connection("player_lose_life", $CanvasLayer/HUD, "_on_player_lose_life")
	player.add_connection("player_die", $CanvasLayer/HUD, "_on_player_die")
	player.add_connection("player_die", self, "_on_player_die")
	
func make_rooms():
	for i in range(num_rooms):
		var pos = Vector2(rand_range(-hspread, hspread), 0)
		var r = Room.instance()
		var w = min_size + randi() % (max_size - min_size)
		var h = min_size + randi() % (max_size - min_size)
		r.make_room(pos, Vector2(w, h) * tile_size)
		$Rooms.add_child(r)	
	# wait for movement to stop
	yield(get_tree().create_timer(.5), 'timeout')
	# cull rooms
	var room_positions = []
	for room in $Rooms.get_children():
		if randf() < cull:
			room.queue_free()
		else:
			room.mode = RigidBody2D.MODE_STATIC
			room_positions.append(Vector3(room.position.x,
										room.position.y, 0))
	yield(get_tree(), 'idle_frame')
	# generate mst
	path = find_mst(room_positions)
		
func _draw():
	for room in $Rooms.get_children():
		draw_rect(Rect2(room.position - room.size, room.size * 2),
				Color(32, 228, 0), false)
	if path:
		for p in path.get_points():
			for c in path.get_point_connections(p):
				var pp = path.get_point_position(p)
				var cp = path.get_point_position(c)
				draw_line(Vector2(pp.x, pp.y), Vector2(cp.x, cp.y),
						Color(1, 1, 0), 15, true)
	
func _process(delta):
	if not dead:
		update()
	
func _input(event):
	"""
	if event.is_action_pressed('ui_select'):
		for n in $Rooms.get_children():
			n.queue_free()
		path = null
		make_rooms()
	
	if event.is_action_pressed("ui_focus_next"):
		make_map()
		place_things()
	
	if event.is_action_pressed('ui_cancel'):
		for r in $Rooms.get_children():
			r.get_node("CollisionShape2D").shape = null
		player = Player.instance()
		add_child(player)
		player.position = start_room.position
	"""

func place_things():
	for room in $Rooms.get_children():
		place_doors(room)
		place_mobs(room)
		
func place_mobs(room):
	var qtd_mobs = min_mobs + randi() % (max_mobs - min_mobs)
	for i in range(qtd_mobs):
		var m = mob.instance()
		var s = (room.size).floor()
		var p = (room.position).floor() - s
		var x = rand_range(p.x + 3*tile_size, s.x*2 + p.x - tile_size*3)
		var y = rand_range(p.y + 3*tile_size, s.y*2 + p.y - tile_size*2)
		m.make_mob(Vector2(x, y), nav)
		room.add_mob(m)
	
	
func place_doors(room):
	var pos = Map.world_to_map(room.position)
	var xs = [pos.x]
	var ys = [pos.y]
	while xs:
		var x = xs.pop_front()
		var y = ys.pop_front()
		if Map.get_cell(x, y) == 0 and visited.get_cell(x, y) == -1:
			visited.set_cell(x, y, 1)
			if Map.get_cell(x + 1, y) == 1 and Map.get_cell(x - 1, y) == 1 or Map.get_cell(x, y + 1) == 1 and Map.get_cell(x, y - 1) == 1:
				Map.set_cell(x, y, 3)
				room.add_door(x, y)
			else:
				var adjx = [1,-1, 0, 0]
				var adjy = [0, 0, 1,-1]
				for i in range(4):
					xs.append(x + adjx[i])
					ys.append(y + adjy[i])





func find_mst(nodes):
	# Prim's algorithm
	var path = AStar.new()
	path.add_point(path.get_available_point_id(), nodes.pop_front())
	
	# repeat until no more nodes to add
	while nodes:
		var min_dist = INF # minimum distance so far
		var min_p = null # position of that node
		var p = null # current node
		# loop through points in path
		for p1 in path.get_points():
			p1 = path.get_point_position(p1)
			# loop through the remaining nodes
			for p2 in nodes:
				if p1.distance_to(p2) < min_dist:
					min_dist = p1.distance_to(p2)
					min_p = p2
					p = p1
		var n = path.get_available_point_id()
		path.add_point(n, min_p)
		path.connect_points(path.get_closest_point(p), n)
		nodes.erase(min_p)
	return path
	
func make_map():
	# create a tilemap from the generated rooms and path
	Map.clear()
	find_start_room()
	find_end_room()
	
	# Fill tlemap with walls then carve empty rooms
	var full_rect = Rect2()
	for room in $Rooms.get_children():
		var r = Rect2(room.position-room.size,
				room.get_node("CollisionShape2D").shape.extents*2)
		full_rect = full_rect.merge(r)
	var topleft = Map.world_to_map(full_rect.position)
	var bottomright = Map.world_to_map(full_rect.end)
	for x in range(topleft.x, bottomright.x):
		for y in range(topleft.y, bottomright.y):
			Map.set_cell(x, y, 1)
			visited.set_cell(x, y, -1)
	
	# Crave rooms
	for room in $Rooms.get_children():
		var s = (room.size / tile_size).floor()
		var pos = Map.world_to_map(room.position)
		var ul = (room.position / tile_size).floor() - s
		for x in range(2, s.x * 2 - 1):
			for y in range(2, s.y * 2 - 1):
				Map.set_cell(ul.x + x, ul.y + y, 0)
				"""
				if y == 2: # top of the room
					Map.set_cell(ul.x + x, ul.y + y, 2)
					if x == 2: # left corner
						Map.set_cell(ul.x + x, ul.y + y, 1)
					if x == s.x*2-2: # right corner
						Map.set_cell(ul.x + x, ul.y + y, 6)	
				if y == s.y*2-2: # bottom of the room
					Map.set_cell(ul.x + x, ul.y + y, 34)
					if x == 2: # left corner
						Map.set_cell(ul.x + x, ul.y + y, 33)
					if x == s.x*2-2: # right corner
						Map.set_cell(ul.x + x, ul.y + y, 38)
				if x == 2: # left wall
					if y > 2 && y < s.y*2-2:
						Map.set_cell(ul.x + x, ul.y + y, 9)
				if x == s.x*2-2:
					if y > 2 && y < s.y*2-2:
						Map.set_cell(ul.x + x, ul.y + y, 14)
				"""
	
	# crave corridors
	var corridors = []
	for room in $Rooms.get_children():
		# Carve connecting corridor
		var p = path.get_closest_point(Vector3(room.position.x, 
											room.position.y, 0))
		for conn in path.get_point_connections(p):
			if not conn in corridors:
				var start = Map.world_to_map(Vector2(path.get_point_position(p).x,
													path.get_point_position(p).y))
				var end = Map.world_to_map(Vector2(path.get_point_position(conn).x,
													path.get_point_position(conn).y))									
				carve_path(start, end)
		corridors.append(p)

func carve_path(pos1, pos2):
	#  carve a path between two points
	var x_diff = sign(pos2.x - pos1.x)
	var y_diff = sign(pos2.y - pos1.y)
	if x_diff == 0: x_diff = pow(-1.0, randi() % 2)
	if y_diff == 0: y_diff = pow(-1.0, randi() % 2)
	# choose either do 
	var x_y = pos1
	var y_x = pos2
	var rrr = (randi() % 2) > 0
	if rrr:
		x_y = pos2
		y_x = pos1
	for x in range(pos1.x, pos2.x + x_diff, x_diff):
		Map.set_cell(x, x_y.y, 0) # corredor
		"""
		if Map.get_cell(x, x_y.y) in [0, 1, 6]:
			Map.set_cell(x, x_y.y, 24) # corredor
			# if cell to the left is
			if Map.get_cell(x - 1, x_y.y) in [33, 38]: # |_ or _|
				Map.set_cell(x - 1, x_y.y, 24) # replace the cell with corridor
			elif Map.get_cell(x - 1, x_y.y) in [9, 14]: # | : or : |
				Map.set_cell(x - 1, x_y.y, 10) # replace the cell with cross road
			elif Map.get_cell(x - 1, x_y.y) in [4]: # | |
				Map.set_cell(x - 1, x_y.y, 9) # replace the cell with left wall only
			
			# if the cell to the right
			if Map.get_cell(x + 1, x_y.y) in [33, 38]: # |_ or _|
				Map.set_cell(x + 1, x_y.y, 24) # replace the cell with corridor
			elif Map.get_cell(x + 1, x_y.y) in [9, 14]: # | : or : |
				Map.set_cell(x + 1, x_y.y, 10) # replace the cell with cross road
			elif Map.get_cell(x + 1, x_y.y) in [4]: # | |
				Map.set_cell(x + 1, x_y.y, 14) # replace the cell with right wall only
			
			if Map.get_cell(x + 1, x_y.y) in [0]:
				Map.set_cell(x, x_y.y, 38) # bottom right corner
			elif Map.get_cell(x - 1, x_y.y) in [0]:
				Map.set_cell(x, x_y.y, 33) # bottom left corner
		elif Map.get_cell(x, x_y.y) in [2]:
			Map.set_cell(x, x_y.y, 10) # chão
		if Map.get_cell(x, x_y.y - 1) == 0:
			Map.set_cell(x, x_y.y - 1, 2) # parede
		elif Map.get_cell(x, x_y.y - 1) in [24, 34, 33, 38]:
			Map.set_cell(x, x_y.y - 1, 10) # chão
		"""
			
	
	# corredores verticais
	var lsty
	for y in range(pos1.y, pos2.y + y_diff, y_diff):
		Map.set_cell(y_x.x, y, 0)
		"""
		lsty = y
		if Map.get_cell(y_x.x, y) in [0, 1, 2, 6]:
			Map.set_cell(y_x.x, y, 4)
			# if the cell to the top is
			if Map.get_cell(y_x.x, y - 1) in [33]: # |_
				Map.set_cell(y_x.x, y - 1, 9) # replace with | :
			elif Map.get_cell(y_x.x, y - 1) in [38]: # _|
				Map.set_cell(y_x.x, y - 1, 14) # replace with : |
			elif Map.get_cell(y_x.x, y - 1) in [24]: # _
				if Map.get_cell(y_x.x - 1, y - 1) in [24] and Map.get_cell(y_x.x + 1, y - 1) in [24]: # if its a ___
					Map.set_cell(y_x.x, y - 1, 10) # replace with . .
				elif Map.get_cell(y_x.x - 1, y - 1) in [24]: # if its a  __
					Map.set_cell(y_x.x, y - 1, 14) # replace with | :
				elif Map.get_cell(y_x.x + 1, y - 1) in [24]: # if its a  __
					Map.set_cell(y_x.x, y - 1, 9) # replace with : |
			elif Map.get_cell(y_x.x, y - 1) in [34]: # begin of room
				Map.set_cell(y_x.x, y - 1, 10) # replace with ground
	lsty = lsty - 1
	if Map.get_cell(y_x.x, lsty + 1) in [24]: # if next cell is end of corridor
		if not Map.get_cell(y_x.x + 1, lsty + 1) in [24] and Map.get_cell(y_x.x - 1, lsty + 1) in [24]:
			Map.set_cell(y_x.x, lsty + 1, 38) # replace with _|
		elif Map.get_cell(y_x.x + 1, lsty + 1) in [24] and not  Map.get_cell(y_x.x - 1, lsty + 1) in [24]:
			Map.set_cell(y_x.x, lsty + 1, 33) # replace with |_
	"""

func find_start_room():
	var min_x = INF
	for room in $Rooms.get_children():
		if room.position.x < min_x:
			start_room = room
			min_x = room.position.x

func find_end_room():
	var max_x = -INF
	for room in $Rooms.get_children():
		if room.position.x > max_x:
			end_room = room
			max_x = room.position.x