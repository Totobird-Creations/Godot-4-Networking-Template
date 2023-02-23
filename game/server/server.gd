extends Node3D
class_name GameServer;


var _enet_peer : ENetMultiplayerPeer = ENetMultiplayerPeer.new();

var _pending_connections  : PackedInt32Array = PackedInt32Array();
var _approved_connections : PackedInt32Array = PackedInt32Array();

var _kicked_reason : String = "";


# Server, Client, Host
func _open_host(port : int, max_clients : int) -> void:
	var error := self._enet_peer.create_server(port, max_clients);
	if (error == OK):
		self.multiplayer.multiplayer_peer      = self._enet_peer;
		self._enet_peer.refuse_new_connections = false;
		error = self.multiplayer.peer_connected.connect(self._player_connected);
		assert(error == OK);
		error = self.multiplayer.peer_disconnected.connect(self._player_disconnected);
		assert(error == OK);
		if (! Init.is_dedicated):
			var __ = self._approved_connections.append(self.multiplayer.get_unique_id());
			self._player_connected(self.multiplayer.get_unique_id());
			Transition.fade_out();
	else:
		Transition.fade_in_for_error("Failed to start server: " + error_string(error) + ".");


# Client, Joiner
func _open_join(address : String, port : int) -> void:
	var error := self._enet_peer.create_client(address, port);
	if (error == OK):
		self.multiplayer.multiplayer_peer = self._enet_peer;
		var timer := self.get_node("connection_timeout") as Timer;
		error = timer.timeout.connect(func():
			self.multiplayer.connected_to_server.disconnect(self._open_join_success);
			Transition.fade_in_for_error("Failed to connect to server: Timed out.");
		);
		assert(error == OK);
		error = self.multiplayer.connected_to_server.connect(self._open_join_success);
		assert(error == OK);
		timer.start();
	else:
		Transition.fade_in_for_error("Failed to connect to server: " + error_string(error) + ".");
func _open_join_success() -> void:
	(self.get_node("connection_timeout") as Timer).stop();
	var error := self.multiplayer.server_disconnected.connect(func():
		var message := "Server disconnected.";
		var reason  := self._kicked_reason.replace("\n", " ");
		if (len(reason.replace(" ", "")) >= 0):
			message += "\n" + reason;
		Transition.fade_in_for_error(message);
	);
	assert(error == OK);
	Transition.fade_in_for_load("Awaiting approval to join...");
	var data := self._request_approval();
	self._player_request_approval.rpc_id(1, data);


# Server
func _open_singleplayer() -> void:
	var __ = self._approved_connections.append(1);
	self._player_connected(1);
	Transition.fade_out();


# All
func _exit_tree() -> void:
	self._enet_peer.refuse_new_connections = true;
	var connection_active := self._enet_peer.get_connection_status() != self._enet_peer.CONNECTION_DISCONNECTED;
	if (connection_active && self.multiplayer.is_server()):
		Util.try_disconnect(self.multiplayer.peer_connected, self._player_connected);
		Util.try_disconnect(self.multiplayer.peer_disconnected, self._player_disconnected);
		for peer in self.multiplayer.get_peers():
			self._enet_peer.disconnect_peer(peer, true);
	if (self.get_game().network_mode != Game.NetworkMode.Join):
		if (! Init.is_dedicated && connection_active):
			self._player_disconnected(self.multiplayer.get_unique_id());
		self._save();
	self._enet_peer.close();


# All
func _notification(notif : int) -> void:
	if (notif == NOTIFICATION_WM_CLOSE_REQUEST):
		if (! Init.is_dedicated):
			Transition.fade_in_for_load("Disconnecting...", false);
	# Save world in case of crash.
	if (notif == NOTIFICATION_CRASH && self.get_game().network_mode != Game.NetworkMode.Join):
		self._save();
	# Exit if requested.
	if (notif == NOTIFICATION_WM_CLOSE_REQUEST):
		if (Init.is_dedicated):
			self.get_tree().quit(0);
		else:
			if (Transition.is_fading):
				await(Transition.faded_in);
			Transition.fade_out();
			var error := self.get_tree().change_scene_to_file("res://menu/menu.tscn");
			assert(error == OK);
	# Exit if crashed.
	if (notif == NOTIFICATION_CRASH):
		self.get_tree().quit(1);



# Host
# Called when a new player attempts to connect.
func _player_connected(peer_id : int) -> void:
	if (peer_id == 1):
		self._player_joined(peer_id);
	else:
		if (! peer_id in self._pending_connections && ! peer_id in self._approved_connections):
			self._player_connecting(peer_id);
			var __ = self._pending_connections.append(peer_id);
			var timeout     := self.get_node("approval_timeout");
			var timer       := Timer.new();
			timer.name       = str(peer_id);
			timer.wait_time  = 2.5;
			timer.autostart  = false;
			timer.one_shot   = true;
			var error := timer.timeout.connect(func():
				timer.stop();
				timer.queue_free();
				self._player_approval_timeout(peer_id);
				self.kick_player(peer_id, "Approval timed out.");
			);
			assert(error == OK);
			timeout.add_child(timer);
			timer.start();

# Host
@rpc("any_peer")
func _player_request_approval(data : Dictionary) -> void:
	var peer_id := self.multiplayer.get_remote_sender_id();
	if (peer_id == 0): peer_id = 1;
	if (peer_id in self._pending_connections && ! peer_id in self._approved_connections):
		self._pending_connections.remove_at(self._pending_connections.find(peer_id));
		var result := self._player_requested_approval(peer_id, data);
		if (result.is_ok()):
			var timeout := self.get_node("approval_timeout");
			if (timeout.has_node(str(peer_id))):
				var timer := timeout.get_node(str(peer_id)) as Timer;
				timer.stop();
				timer.queue_free();
			var __ = self._approved_connections.append(peer_id);
			self._player_approved.rpc_id(peer_id);
			self._player_joined(peer_id);
		else:
			self.kick_player(peer_id, result.get_err());

# Joiner
@rpc
func _player_approved() -> void:
	if (self.multiplayer.get_remote_sender_id() == 1):
		(self.get_node("connection_timeout") as Timer).stop();
		Transition.fade_out();

# Joiner
@rpc
func _kicked_by_server(message : String) -> void:
	if (self.multiplayer.get_remote_sender_id() == 1):
		self._kicked_reason = message;
		self._client_registered_kick.rpc_id(1);

# Host
@rpc("any_peer")
func _client_registered_kick() -> void:
	self._client_registered_kick_inner(self.multiplayer.get_remote_sender_id());

# Host
func _client_registered_kick_inner(peer_id : int) -> void:
	var timeout := self.get_node("kick_timeout");
	if (timeout.has_node(str(peer_id))):
		var timer := timeout.get_node(str(peer_id)) as Timer;
		timer.stop();
		timer.queue_free();
	self._enet_peer.disconnect_peer(peer_id);

# Host
# Called when a player attempts to disconnect.
func _player_disconnected(peer_id : int) -> void:
	var timeout := self.get_node("approval_timeout");
	if (timeout.has_node(str(peer_id))):
		var timer := timeout.get_node(str(peer_id)) as Timer;
		if (timer != null):
			timer.stop();
			timer.queue_free();
	if (peer_id in self._pending_connections):
		self._pending_connections.remove_at(self._pending_connections.find(peer_id));
	if (peer_id in self._approved_connections):
		self._player_left(peer_id);
		for entity in self.get_entity_manager().get_children():
			var index := entity._watchers.find(peer_id) as int;
			if (index != -1):
				entity._watchers.remove_at(index);
		self._approved_connections.remove_at(self._approved_connections.find(peer_id));



# Joiner
@rpc
func _spawn_entity(id : int, type : String, data : Dictionary) -> void:
	if (self.multiplayer.get_remote_sender_id() == 1):
		var handler = load("res://game/server/handler/entity/" + type + ".tscn");
		if (handler is PackedScene):
			handler = handler.instantiate();
		else:
			handler = null;
		if (handler is ServerEntityHandler):
			var entity := Entity.new(handler);
			entity.id   = id
			self.get_entity_manager()._spawn_entity_from_server(entity);
			self.get_entity_manager()._update_entity_from_server(entity, data);
		elif (typeof(handler) == TYPE_OBJECT):
			handler.free();

# Host, Joiner
@rpc("any_peer")
func _update_entity(id : int, data : Dictionary) -> void:
	var peer_id := self.multiplayer.get_remote_sender_id();
	if (peer_id == 1):
		self.get_entity_manager()._update_entity_id_from_server(id, data);
	elif (self.is_host()):
		self.get_entity_manager()._update_entity_id_from_client(peer_id, id, data);

# Host, Joiner
@rpc("any_peer", "unreliable")
func _update_entity_unreliable(id : int, data : Dictionary) -> void:
	self._update_entity(id, data);

# Joiner
@rpc
func _despawn_entity(id : int) -> void:
	if (self.multiplayer.get_remote_sender_id() == 1):
		self.get_entity_manager()._despawn_entity_id_from_server(id);




func get_peer_id() -> int:
	if (self._enet_peer.get_connection_status() == self._enet_peer.CONNECTION_DISCONNECTED):
		return 1;
	else:
		return self.multiplayer.get_unique_id();

func is_host() -> bool:
	return self._enet_peer.get_connection_status() == self._enet_peer.CONNECTION_DISCONNECTED || self.multiplayer.is_server();


func get_game() -> Game:
	return self.get_parent() as Game;

func get_entity_manager() -> GameServerEntityManager:
	return self.get_node("entity_manager") as GameServerEntityManager;





#
# CALL THESE FUNCTIONS.
#


# Host
func kick_player(peer_id : int, message : String = "") -> void:
	var timeout := self.get_node("kick_timeout");
	if (peer_id == 1): print("Can not kick the server.");
	elif (! timeout.has_node(str(peer_id))):
		print("Kicked " + str(peer_id) + ": ", message);
		var timer       := Timer.new();
		timer.name       = str(peer_id);
		timer.wait_time  = 2.5;
		timer.autostart  = false;
		timer.one_shot   = true;
		var error := timer.timeout.connect(func(): self._client_registered_kick_inner(peer_id));
		assert(error == OK);
		self._kicked_by_server.rpc_id(peer_id, message);
		timeout.add_child(timer);
		timer.start();


#
# MODIFY THESE FUNCTIONS.
#


# Server
# Called when a player first attempts to connect.
func _player_connecting(peer_id : int) -> void:
	print(str(peer_id) + " is attempting to connect.");

# Joiner
# Send data to the server at startup.
# The server will review this and decide whether or not you are allowed to join.
func _request_approval() -> Dictionary:
	return {};

# Host
# Called when a player attempts to connect, after it sends initial data.
# Useful for checking if the player is using the same game version.
# Return `Result.ok()` if the client is cleared to join.
# Return a `Result.error("Error message.")` if the client should be rejected. The given message will be shown to the client.
func _player_requested_approval(_peer_id : int, _data : Dictionary) -> Result:
	var rng := RandomNumberGenerator.new();
	rng.randomize();
	if (rng.randf_range(0.0, 1.0) <= 0.5):
		return Result.err("Lol, unlucky.");
	else:
		return Result.ok();

# Host
# Called when a player attempted to connect, but timed out the approval step.
func _player_approval_timeout(peer_id : int) -> void:
	print(str(peer_id) + " attempted to connect but timed out.");

const PLAYER : PackedScene = preload("res://game/server/handler/entity/player.tscn");

# Dictionary[int, int]
# - Key   : Peer id.
# - Value : Entity id.
var players : Dictionary = {};

# Server
# Called when a player attempts to connect, and is approved to join.
func _player_joined(peer_id : int) -> void:
	print(str(peer_id) + " has joined.");
	var handler           := PLAYER.instantiate();
	handler.owner_peer     = peer_id;
	var entity            := Entity.new(handler);
	var entity_id         := self.get_entity_manager().spawn_entity(entity);
	self.players[peer_id]  = entity_id;

# Server
# Called when a player had been approved to join, and has disconnected.
func _player_left(peer_id : int) -> void:
	self.get_entity_manager().despawn_entity_id(self.players[peer_id]);
	var __ = self.players.erase(peer_id);
	print(str(peer_id) + " has left.");


# Server
func _save() -> void:
	print("Saved.");
