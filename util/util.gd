extends Node
class_name Util;


static func try_disconnect(sig : Signal, fn : Callable) -> void:
	if (sig.is_connected(fn)):
		sig.disconnect(fn);
