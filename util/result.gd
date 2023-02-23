class_name Result;


var _success : bool   = false;
var _error   : String = "";


static func ok() -> Result:
	var result := Result.new();
	result._success = true;
	result._error   = "";
	return result;


static func err(error : String) -> Result:
	var result := Result.new();
	result._success = false;
	result._error   = error;
	return result;


func is_ok() -> bool:
	return self._success;

func get_err() -> String:
	return self._error;
