extends Node
class_name Entity;


# The entity instance id.
var id : int;
# The entity handler.
var server_handler : ServerEntityHandler;
var client_handler : ClientEntityHandler;
# Paths to entity handler scripts.
var _server_handler_path : String;
# Connected players who currently have this entity loaded.
@warning_ignore("unused_private_class_variable")
var _watchers : PackedInt32Array = [];
# Data that connected players have on this entity.
# Dictionary[int, Dictionary[Variant, Variant]]
@warning_ignore("unused_private_class_variable")
var _watcher_data : Dictionary = {};

# Is from server.
@warning_ignore("unused_private_class_variable")
var _from_server : bool = false;
# Initialisation has been handled.
var _init_handled : bool = false;
# Entity should despawn as soon as possible.
var _queue_despawn : bool = false;


func _init(handler : ServerEntityHandler) -> void:
	self.server_handler = handler;
	var path := (self.server_handler.scene_file_path as String).lstrip("res://game/server/handler/entity").lstrip("/").split(".");
	path.remove_at(len(path) - 1);
	self._server_handler_path = ".".join(path);

func _ready() -> void:
	self.add_child(self.server_handler);



func get_game() -> Game:
	return self.get_parent().get_game() as Game;

func get_server() -> GameServer:
	return self.get_parent().get_server() as GameServer;

# May be null.
func get_client() -> GameClient:
	return self.get_parent().get_client() as GameClient;

func get_server_entity_manager() -> GameServerEntityManager:
	return self.get_server().get_entity_manager() as GameServerEntityManager;



func despawn() -> void:
	self._queue_despawn = true;



func _enable_client_handler() -> void:
	self.client_handler = self.server_handler.create_client();
	self.get_game().get_client().get_client_world().get_entity_manager().add_child(self.client_handler);

func _disable_client_handler() -> void:
	if (self.client_handler != null):
		self.client_handler.queue_free();
		self.client_handler = null;
