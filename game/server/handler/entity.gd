extends Node3D
class_name ServerEntityHandler;


var _entity : Entity;


# OVERRIDE
# Create a `ClientEntityHandler` instance, which will be displayed on the screen.
# If you would like to modify the client handler in the `process_tick` or `physics_process_tick` methods, make sure to store it before returning it.
# Return `null` if the client should not display anything.
# Only called on the client.
func create_client() -> ClientEntityHandler:
	return null;


# OVERRIDE
# Whether or not to send information about this entity to a client.
# Useful for hiding entities from clients when they get too far from it.
# This will be called right before `process_tick` is called.
# Only called on the host.
func sync_allowed_with(_target_peer_id : int) -> bool:
	return true;

# OVERRIDE
# Return a `Dictionary` of values to be sent to the target_peer_id.
# If the value is not a `DeliveryMethod`, it will be mapped to the default method.
# The `received_data_from` function will be called twice: Once for unreliable (if it arrives) and once for reliable.
# Even if the delivery method is set to be unreliable, it will be sent reliably when the spawn signal is sent to the client.
func send_data_to(_target_peer_id : int) -> Dictionary:
	return {};

# OVERRIDE
func received_data_from(_source_peer_id : int, _data : Dictionary) -> void:
	pass;



func despawn() -> void:
	self._entity.despawn();



func get_id() -> int:
	return self._get_entity().id;

func get_server() -> GameServer:
	return self._get_entity().get_server();

func get_entity_manager() -> GameServerEntityManager:
	return self._get_entity().get_entity_manager();

func _get_entity() -> Entity:
	return self._entity;
