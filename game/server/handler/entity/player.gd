extends ServerEntityHandler;


const CLIENT_HANDLER : PackedScene = preload("res://game/client/handler/entity/player.tscn");

var owner_peer : int     = -1;
var input      : Vector3 = Vector3.ZERO;

@onready var body   : CharacterBody3D     = self.get_node("body");
var          client : ClientEntityHandler;


func create_client() -> ClientEntityHandler:
	self.client    = CLIENT_HANDLER.instantiate();
	client.visible = false;
	return self.client;


func send_data_to(target_peer_id : int) -> Dictionary:
	var data := {};
	
	if (self.get_server().is_host()):
		data = {
			position = DeliveryMethod.new(body.position).reliable(false),
			input    = DeliveryMethod.new(self.input).only_send_on_change(true)
		};
		if (target_peer_id == self.owner_peer):
			data["owner_peer"] = DeliveryMethod.new(self.owner_peer).only_send_on_change(true);

	elif (target_peer_id == 1 && self.get_server().get_peer_id() == self.owner_peer):
		data = {
			input = DeliveryMethod.new(self.input).only_send_on_change(true)
		};

	return data;


func received_data_from(source_peer_id : int, data : Dictionary) -> void:

	if (self.get_server().is_host()):
		if (source_peer_id == self.owner_peer):
			self.input = data.get("input", self.input);

	elif (source_peer_id == 1):
		self.owner_peer = data.get("owner_peer", self.owner_peer);
		body.position   = data.get("position", body.position);
		# The server should not be able to control the owning player's input.
		if (self.owner_peer != self.get_server().get_peer_id()):
			self.input = data.get("input", self.input);



func _physics_process(delta : float) -> void:

	# Handle input, if this entity is managed by this client.
	var is_owner := (self.get_server().get_peer_id() == self.owner_peer) as bool;
	if (is_owner):
		self.input = Vector3(
			Input.get_axis("move_left", "move_right"),
			0.0,
			Input.get_axis("move_up", "move_down"),
		);

	# Handle the physics of the entity.
	var __ = body.move_and_collide(self.input * delta * 10.0);

	# Handle the visual part of the entity.
	if (self.client != null && ! self.client.is_queued_for_deletion()):
		self.client.get_node("indicator").visible = is_owner;
		if (self.client.visible):
			# This is so that the entity doesn't jitter around too much on clients.
			self.client.position = self.client.position + (body.position - self.client.position) * 0.5;
			#                                                                                      ^^^ This value can be played around with the perfect the effect.
		else:
			# This is so that it doesn't look like the entity moved from 0,0 to it's position when the entity first loads.
			self.client.visible = true;
			self.client.position = body.position;
