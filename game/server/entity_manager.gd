extends Node
class_name GameServerEntityManager;


var _next_entity_id : int        = 0;
# Dictionary[int, Entity]
# - Key   : Entity ID.
# - Value : Entity.
var _entities       : Dictionary = {};


func get_game() -> Game:
	return self.get_server().get_game();

func get_server() -> GameServer:
	return self.get_parent() as GameServer;

# May be null.
func get_client() -> GameClient:
	return null;



func spawn_entity(entity : Entity) -> int:
	entity.server_handler._entity = entity;
	if (! entity._init_handled):
		entity._init_handled       = true;
		entity.id                  = self._next_entity_id;
		self._next_entity_id      += 1;
		self._entities[entity.id]  = entity;
		self.add_child(entity);
	return entity.id;

func _spawn_entity_from_server(entity : Entity) -> void:
	var prev_entity           := self._entities.get(entity.id) as Entity;
	entity._init_handled       = true;
	entity._from_server        = true;
	self._entities[entity.id]  = entity;
	self.add_child(entity);
	self._next_entity_id       = max(self._next_entity_id, entity.id + 1);
	# If there is a client side only entity and it's id matches the entity received from the server, change its id.
	# This is to keep ids between the server and client in sync.
	if (prev_entity != null && ! prev_entity._from_server):
		prev_entity.id = self._next_entity_id;
		prev_entity.server_handler.id_changed(entity.id, prev_entity.id);
		self._next_entity_id += 1;


func _update_entity(entity : Entity, data : Dictionary, filter : PackedStringArray) -> void:
	for property in filter:
		var next_value = data.get(property);
		if (next_value != null):
			entity.server_handler.set(property, next_value);

func _update_entity_from_server(entity : Entity, data : Dictionary) -> void:
	if (entity._from_server):
		entity.server_handler.received_data_from(1, data);

func _update_entity_id_from_server(entity_id : int, data : Dictionary) -> void:
	var entity = self._entities.get(entity_id);
	if (entity != null):
		self._update_entity_from_server(entity, data);

func _update_entity_id_from_client(peer_id : int, entity_id : int, data : Dictionary) -> void:
	var entity = self._entities.get(entity_id);
	if (entity != null):
		entity.server_handler.received_data_from(peer_id, data);


func despawn_entity(entity : Entity) -> void:
	entity.despawn();

func despawn_entity_id(entity_id : int) -> void:
	var entity = self._entities.get(entity_id);
	if (entity != null):
		self.despawn_entity(entity);

func _despawn_entity_id_from_server(entity_id : int) -> void:
	var entity = self._entities.get(entity_id);
	if (entity != null && entity._from_server):
		self.despawn_entity(entity);



func _process(_delta : float) -> void:
	for _entity in self._entities.values():
		var entity = _entity as Entity;
		if (self.get_server()._enet_peer.get_connection_status() == self.get_server()._enet_peer.CONNECTION_DISCONNECTED || self.multiplayer.is_server()):
			var next_watched = PackedInt32Array();
			for peer_id in self.get_server()._approved_connections:
				var sync = entity.server_handler.sync_allowed_with(peer_id) && ! entity._queue_despawn;
				# Add watcher.
				if (sync && ! peer_id in entity._watchers):
					if (peer_id == 1 || peer_id == 0):
						entity._enable_client_handler();
					elif (peer_id in self.get_server().multiplayer.get_peers()):
						var data := entity.server_handler.send_data_to(peer_id) as Dictionary;
						self.get_server()._spawn_entity.rpc_id(peer_id, entity.id, entity._server_handler_path, data);
				# Remove watcher.
				elif (! sync && peer_id in entity._watchers):
					if (peer_id == 1 || peer_id == 0):
						entity._disable_client_handler();
					elif (peer_id in self.get_server().multiplayer.get_peers()):
						self.get_server()._despawn_entity.rpc_id(peer_id, entity.id);
				elif (sync && peer_id != 1 && peer_id != 0):
					if (peer_id in self.get_server().multiplayer.get_peers()):
						var data := entity.server_handler.send_data_to(peer_id) as Dictionary
						self.get_server()._update_entity.rpc_id(peer_id, entity.id, data);
				if (sync):
					var __ = next_watched.append(peer_id);
				elif (entity._queue_despawn):
					if (peer_id == 1 || peer_id == 0):
						entity._disable_client_handler();
					entity.queue_free();
					var __ = self._entities.erase(entity.id);
			entity._watchers = next_watched;
		else: # self.get_server()._enet_peer.get_connection_status() != self.get_server()._enet_peer.CONNECTION_DISCONNECTED && ! self.multiplayer.is_server()
			if (! self.get_server().multiplayer.get_unique_id() in entity._watchers):
				entity._enable_client_handler();
				entity._watchers.append(self.get_server().multiplayer.get_unique_id());
			if (entity._queue_despawn):
				entity._disable_client_handler();
				entity.queue_free();
				var __ = self._entities.erase(entity.id);
			else:
				var data := entity.server_handler.send_data_to(1) as Dictionary;
				self.get_server()._update_entity.rpc_id(1, entity.id, data);
