extends CharacterBody3D

@onready var gunRay = $Head/Camera3d/RayCast3d as RayCast3D
@onready var Cam = $Head/Camera3d as Camera3D
var _bullet_scene = preload("res://Scenes/Bullet/Bullet.tscn")
var mouseSensibility = 1200
var mouse_relative_x = 0
var mouse_relative_y = 0
var damage = 10
const SPEED = 5.0
const JUMP_VELOCITY = 4.5
var bullets_left = 100
var looking_point
var enemy_loc = {}
var last_distance = null
var min_distance = null
var total_reward = 0
var have_looked = false

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

var min_x = -10
var max_x = 10
var min_y = -10
var max_y = 10
var agent_name
var agent_n
var last_modified_time = null
var actions_left = 1000
var left_distance = null
var right_distance = null
var delta_dist = 0
var first_time = false
var server := TCPServer.new()


func _ready():
	#Captures mouse and stops rgun from hitting yourself
	agent_name = get_parent().name
	agent_n = int(agent_name.split("agent")[-1])
	$Agent_n.text = str(agent_n)
	$Info.text = "Agent%d: \n Bullets Left: %d, Act Left: %d, Action:" % [agent_n, bullets_left, actions_left]
	$Info.position.y += (agent_n - 1) * 50
	gunRay.add_exception(self)
	$Is_touch_enemy.add_exception(self)
	$Is_touch_enemy.add_exception(get_parent().get_parent().get_node("Floor"))
#	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	set_process_input(true)
	add_to_group("Players")
	if not enemy_loc:
		var enemy = get_parent().get_parent().get_node("Enemy")
		enemy_loc["x"] = enemy.position.x
		enemy_loc["y"] = enemy.position.y
		enemy_loc["z"] = enemy.position.z
	server.listen(4240 + agent_n)

func _process(delta):
	var action = ''
	if server.is_connection_available() and not first_time:
		GlobalVars.peer = server.take_connection()
		save_state(0, 0)
	if GlobalVars.peer:
		action = GlobalVars.peer.get_utf8_string(GlobalVars.peer.get_available_bytes())
	if $Is_touch_enemy.is_colliding() and $Is_touch_enemy.get_collider().name == "Enemy":
		var random_x = randf_range(min_x, max_x)
		var random_y = randf_range(min_y, max_y)
		set_position(Vector3(random_x, 0, random_y))
		first_time = true
	if first_time:
		first_time = false
		var camera_position = $Head/Camera3d.global_transform.origin
		var camera_forward = -$Head/Camera3d.global_transform.basis.z.normalized()
		looking_point = camera_position + camera_forward
		last_distance = Vector3(looking_point).distance_to(Vector3(enemy_loc['x'], enemy_loc['y'], enemy_loc['z']))
		left_distance = turn_head("left")
		turn_head("right", false)
		right_distance = turn_head("right")
		turn_head("left", false)
		min_distance = last_distance
	if action == '' or action == 'starting':
		return
	play_action(action)

func _physics_process(delta):
	if not is_on_floor():
		velocity.y -= gravity * delta
	if Input.is_action_just_pressed("Jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	var input_dir = Input.get_vector("moveLeft", "moveRight", "moveUp", "moveDown")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
	move_and_slide()
	
		
func turn_head(pos, return_dist=true):
	if pos == "left":
		rotation.y -= -100.0 / mouseSensibility
		$Head.rotation.x -= 0.0 / mouseSensibility
		$Head.rotation.x = clamp($Head.rotation.x, deg_to_rad(-90), deg_to_rad(90))
	elif pos == "right":
		rotation.y -= 100.0 / mouseSensibility
		$Head.rotation.x -= 0.0 / mouseSensibility
		$Head.rotation.x = clamp($Head.rotation.x, deg_to_rad(-90), deg_to_rad(90))
	if return_dist:
		var camera_position = $Head.global_transform.origin
		var camera_forward = -$Head.global_transform.basis.z.normalized()
		var l = camera_position + camera_forward
		return Vector3(l).distance_to(Vector3(enemy_loc['x'], enemy_loc['y'], enemy_loc['z']))
	
		
func play_action(action):
	if actions_left > 0:
		actions_left -= 1
		var done = 0
		if actions_left == 0:
			done = 1
		var t = "Agent%d: Total Reward: %d, State: %d \n    Bullets Left: %d, Act Left: %d, Action: %s \n    Left D: %.02f, Right D: %.02f, Curr D: %.02f, Delta Dx20: %.02f"
		if action == "shoot":
			shoot()
			$Info.text = t % [agent_n, total_reward, GlobalVars.state_num, bullets_left, actions_left, action, left_distance, right_distance, last_distance, delta_dist*20]
			return
		elif action == "left":
			right_distance = last_distance
			rotation.y -= -100.0 / mouseSensibility
			$Head.rotation.x -= 0.0 / mouseSensibility
			$Head.rotation.x = clamp($Head.rotation.x, deg_to_rad(-90), deg_to_rad(90))
			left_distance = turn_head("left")
			turn_head("right", false)
		elif action == "right":
			left_distance = last_distance
			rotation.y -= 100.0 / mouseSensibility
			$Head.rotation.x -= 0.0 / mouseSensibility
			$Head.rotation.x = clamp($Head.rotation.x, deg_to_rad(-90), deg_to_rad(90))
			right_distance = turn_head("right")
			turn_head("left", false)
		var camera_position = $Head.global_transform.origin
		var camera_forward = -$Head.global_transform.basis.z.normalized()
		looking_point = camera_position + camera_forward  # Adjust the distance as needed
		var distance = Vector3(looking_point).distance_to(Vector3(enemy_loc['x'], enemy_loc['y'], enemy_loc['z']))
		var reward = 0
		if distance < last_distance:
			reward = 1
		delta_dist = abs(distance - last_distance)
		$Info.text =  t % [agent_n, total_reward, GlobalVars.state_num, bullets_left, actions_left, action, left_distance, right_distance, last_distance, delta_dist*20]
		last_distance = distance
#			reward = max(reward, is_look_on_enemy())
		reward = 0
		total_reward += reward
		save_state(reward, done)

func _input(event):
#	if event.is_action_pressed("Shoot"):
#		shoot()
#	if event is InputEventMouseMotion:
	if false:
		rotation.y -= event.relative.x / mouseSensibility
		$Head.rotation.x -= event.relative.y / mouseSensibility
		$Head.rotation.x = clamp($Head.rotation.x, deg_to_rad(-90), deg_to_rad(90) )
		mouse_relative_x = clamp(event.relative.x, -50, 50)
		mouse_relative_y = clamp(event.relative.y, -50, 10)
		var camera_position = $Head.global_transform.origin

		# Get the camera's forward vector (normal)
		var camera_forward = -$Head/Camera3d.global_transform.basis.z.normalized()

		# Calculate a point where the camera is looking
		looking_point = camera_position + camera_forward  # Adjust the distance as needed
		
		var distance = Vector3(looking_point).distance_to(Vector3(enemy_loc['x'], enemy_loc['y'], enemy_loc['z']))
		
		if last_distance == null:
			last_distance = distance
		
		if min_distance == null:
			min_distance = distance
			
		delta_dist = distance - last_distance
		last_distance = distance
			
		var reward = is_look_on_enemy()		
		#if distance <= last_distance:
		#	reward = 0
		#	last_distance = distance
		#if distance < last_distance:
		#	reward = 100
		#else:
		#	reward = -200
		#last_distance = distance			
		#total_reward += reward
		reward = 0
		save_state(reward, 0)
	

func is_look_on_enemy():
	var reward = -1
	if have_looked:
		reward = -10
	elif last_distance < min_distance:
		reward = 2
		min_distance = last_distance	
	if not gunRay.is_colliding():
		return reward
	var collided_object = gunRay.get_collider()
	if collided_object and collided_object.name == "Enemy":
		reward = 10
		have_looked = true
	return reward


func shoot():
	if bullets_left > 0:
		var reward = 0
		bullets_left -= 1
		var done = 0
		if bullets_left == 0 or actions_left == 0:
			done = 1
		if not gunRay.is_colliding():
			total_reward += reward
			save_state(reward, done)
			return
		var bulletInst = _bullet_scene.instantiate() as Node3D
		bulletInst.set_as_top_level(true)
		get_parent().add_child(bulletInst)
		bulletInst.global_transform.origin = gunRay.get_collision_point() as Vector3
		bulletInst.look_at((gunRay.get_collision_point()+gunRay.get_collision_normal()),Vector3.BACK)
		var collided_object = gunRay.get_collider()
		if collided_object and collided_object.name == "Enemy":
#			collided_object.emit_signal("bullet_collision")
			reward = 5
			total_reward += reward
			save_state(reward, done)
	#		if bullets_left == 0:
	#			total_reward += reward
	#			save_state(reward, 2)
	

func save_state(reward, done):
	var distance = Vector3(looking_point).distance_to(Vector3(enemy_loc['x'], enemy_loc['y'], enemy_loc['z']))
	var data_to_send = {
		"reward" : reward,
#		"pl_x" : looking_point.x,
#		"pl_y" : looking_point.y,
#		"pl_z" : looking_point.z,
#		"enemy_x" : enemy_loc.x,
#		"enemy_y" : enemy_loc.y,
#		"enemy_z" : enemy_loc.z,
#		"bullets_left" : bullets_left,
#		"last_distance" : last_distance,
#		"min_distance" : min_distance,
		"done" : done,
		"current_distance" : distance,
		"left_distance" : left_distance,
		"right_distance" : right_distance,
		"delta_distance" : delta_dist*20,
	}
	var json_string = JSON.stringify(data_to_send)
	GlobalVars.peer.put_data(json_string.to_utf8_buffer())
	GlobalVars.state_num += 1
