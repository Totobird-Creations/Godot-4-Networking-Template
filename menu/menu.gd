extends MarginContainer;


func _notification(notif : int) -> void:
	if (notif == NOTIFICATION_WM_CLOSE_REQUEST):
		self.get_tree().quit(0);


func join() -> void:
	CrossScene.network_address = self.get_node("hbox/join/margin/vbox/address").text;
	CrossScene.network_port    = int(self.get_node("hbox/join/margin/vbox/port").text);
	CrossScene.network_mode    = Game.NetworkMode.Join;
	self.transition();


func host() -> void:
	CrossScene.network_port = int(self.get_node("hbox/host/margin/vbox/port").text);
	CrossScene.network_mode = Game.NetworkMode.Host;
	self.transition();


func singleplayer() -> void:
	CrossScene.network_mode = Game.NetworkMode.None;
	self.transition();


func transition() -> void:
	Transition.fade_in_for_load("Connecting...");
	await(Transition.faded_in);
	var error := self.get_tree().change_scene_to_file("res://game/game.tscn");
	assert(error == OK);
