extends Node;


var is_dedicated : bool = OS.has_feature("dedicated") || DisplayServer.get_name() == "headless";


func _ready() -> void:
	self.multiplayer.multiplayer_peer = null;
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_RESIZE_DISABLED, false);
	var error : int;
	if (self.is_dedicated):
		error = self.get_tree().change_scene_to_file("res://game/game.tscn");
	else:
		error = self.get_tree().change_scene_to_file("res://menu/menu.tscn");
	assert(error == OK);
