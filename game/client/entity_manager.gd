extends Node3D
class_name GameClientEntityManager;


func get_game() -> Game:
	return self.get_client().get_game();

func get_client() -> GameClient:
	return self.get_parent().get_parent() as GameClient;

func get_server() -> GameServer:
	return self.get_game().get_server();
