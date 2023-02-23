extends CanvasLayer;


signal faded_in();


var is_faded_in : bool = false;
var is_fading   : bool = false;


func fade_in_for_load(message : String, cancellable : bool = true) -> void:
	if (Init.is_dedicated):
		self.faded_in.emit();
	else:
		self.get_node("main/vertical/text").text               = message;
		self.get_node("main/vertical/return_to_menu").visible  = cancellable;
		self.get_node("main/vertical/return_to_menu").disabled = false;
		if (self.is_faded_in):
			self.faded_in.emit();
		else:
			self.get_tree().set_pause(true);
			self.is_faded_in = true;
			self.is_fading   = true;
			self.get_node("animation").play("show");
			await(self.faded_in);
			var error := self.get_tree().change_scene_to_file("res://null.tscn");
			assert(error == OK);


func fade_in_for_error(error : String) -> void:
	if (Init.is_dedicated):
		print("FATAL | " + error);
		self.get_tree().quit(1);
	else:
		self.fade_in_for_load(error, true);


func fade_out() -> void:
	if (! Init.is_dedicated && self.is_faded_in):
		self.get_tree().set_pause(false);
		self.get_node("main/vertical/return_to_menu").disabled = true;
		self.get_node("animation").play("hide");
		self.is_faded_in = false;
		self.is_fading   = true;


func _anim_finished(anim_name : StringName) -> void:
	if (anim_name == "show"):
		self.faded_in.emit();
	self.is_fading = false;


func _return_to_menu() -> void:
	if (self.is_faded_in):
		self.get_node("main/vertical/text").text = "Returning to menu...";
		var error := self.get_tree().change_scene_to_file("res://menu/menu.tscn");
		assert(error == OK);
		self.fade_out();
