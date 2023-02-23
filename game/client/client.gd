extends Node
class_name GameClient;


func get_client_world() -> GameClientWorld:
	return self.get_node("world");

func get_game() -> Game:
	return self.get_parent() as Game;
