extends Node
class_name Game;


enum NetworkMode {
	None,
	Host,
	Join
};


const SERVER : PackedScene = preload("res://game/server/server.tscn");
const CLIENT : PackedScene = preload("res://game/client/client.tscn");


@export
var network_mode : NetworkMode = NetworkMode.Join;
@export
var has_client : bool = ! Init.is_dedicated;

var server : GameServer;
var client : GameClient;


func _ready() -> void:
	var port = CrossScene.network_port;
	if (self.has_client):
		self.network_mode = CrossScene.network_mode;
	else:
		self.network_mode = NetworkMode.Host;
	self.server = SERVER.instantiate();
	if (self.has_client):
		self.client = CLIENT.instantiate();
		self.add_child(self.client);
	else:
		self.client = null;
	self.add_child(self.server);
	match (self.network_mode):
		NetworkMode.Host : self.server._open_host(port, 10);
		NetworkMode.Join : self.server._open_join(CrossScene.network_address, port);
		NetworkMode.None : self.server._open_singleplayer();


func get_server() -> GameServer:
	return self.server;

# May be null.
func get_client() -> GameClient:
	return self.client;
