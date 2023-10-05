extends Node3D
var players = []

# Called when the node enters the scene tree for the first time.
func _ready():
	$Epoch.text = "Epoch %d" % GlobalVars.epoch
	var train_list = []
	var s = get_tree().get_nodes_in_group("Players").size()
	train_list.resize(s)
	train_list.fill(true)
	var all_false = false
	for node in get_tree().get_nodes_in_group("Players"):
		players.append(node)
	if GlobalVars.epoch == 0:
		GlobalVars.pid = OS.create_process("/bin/sh", ["-c",". ./.venv/bin/activate && python ./scripts/main.py %d" % len(players)])

func _input(event):
	if event.is_action_pressed("resetGame"):
		reset_game()
	if event.is_action_pressed("quitGame"):
		quit()
		
func quit():
	OS.execute("pkill", ["-P", str(GlobalVars.pid)])	
	get_tree().quit()
	
func reset_game():
	GlobalVars.epoch += 1
	get_tree().reload_current_scene()
	
func _process(delta):
	var reset = true
	for player in players:
		if player.bullets_left > 0 and player.actions_left > 0:
			reset = false
	if reset:
		reset = false
		reset_game()
