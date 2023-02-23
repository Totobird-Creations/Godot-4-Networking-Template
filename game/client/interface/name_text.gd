@tool
extends SubViewportContainer;


var __ready : bool = false;

@export
var text : String = "":
	set(value): 
		text = value;
		if (self.__ready): self.set_text(value);
@export
var rarity : Globals.Rarity = Globals.Rarity.Common:
	set(value):
		rarity = value;
		if (self.__ready): self.set_rarity(value);


func _ready() -> void:
	self.__ready = true;
	self.set_text(self.text);
	self.update_rect();


func set_text(value : String) -> void:
	self.get_node("viewport/text").text = self.text;
	self.update_rect();


func update_rect() -> void:
	var viewport  := self.get_node("viewport") as SubViewport;
	var text      := viewport.get_node("text") as Label;
	text.size      = Vector2i.ZERO;
	viewport.size  = text.size;
	self.size      = text.size;
	self.material.set_shader_parameter("resolution", text.size);


func set_rarity(value : Globals.Rarity) -> void:
	self.material.set_shader_parameter("rarity", value);
