class_name DeliveryMethod;


var _value;
var _reliable            : bool = true;
var _only_send_on_change : bool = false;


func _init(value) -> void:
	self._value = value;


# Whether to use reliable rpc or unreliable rpc.
# Default: true
func reliable(new_reliable : bool) -> DeliveryMethod:
	self._reliable = new_reliable;
	return self;


# If this is `true`, the value will only be sent if it is different from the previously sent value.
# Default: false (Always send, no matter the value)
func only_send_on_change(new_only_send_on_change : bool) -> DeliveryMethod:
	self._only_send_on_change = new_only_send_on_change;
	return self;



static func split_data(peer_id : int, entity : Entity, data : Dictionary, data_reliable : Dictionary, data_unreliable : Dictionary) -> void:
	for key in data.keys():
		var value = data[key];
		if (! value is DeliveryMethod):
			value = DeliveryMethod.new(value);
		if (! entity._watcher_data.has(peer_id)):
			entity._watcher_data[peer_id] = {};
		if (! value._only_send_on_change || ! entity._watcher_data[peer_id].has(key) || value._value != entity._watcher_data[peer_id][key]):
			entity._watcher_data[peer_id][key] = value._value;
			if (value._reliable):
				data_reliable[key] = value._value;
			else:
				data_unreliable[key] = value._value;
