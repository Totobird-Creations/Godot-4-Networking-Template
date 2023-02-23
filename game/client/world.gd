extends Node3D
class_name GameClientWorld;


# Dictionary[int, EntityHandler]
var entities : Dictionary = {};


func spawn_entity(id : int, type : String, _data : Dictionary) -> void:
	if (self.entities.has(id)):
		self.despawn_entity(id);
	var __ = load("res://game/common/entity_handler/" + type + ".gd");

func update_entity(id : int, data : Dictionary) -> void:
	if (self.entities.has(id)):
		self.entities[id].entity.update_entity(data);

func despawn_entity(id : int) -> void:
	if (self.entities.has(id)):
		self.entities[id].queue_free();
		var __ = self.entities.erase(id);


func get_entity_manager() -> GameClientEntityManager:
	return self.get_node("entity_manager") as GameClientEntityManager;
