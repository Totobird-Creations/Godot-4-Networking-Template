extends Node;


func _notification(notif : int) -> void:
	if (notif == NOTIFICATION_WM_CLOSE_REQUEST):
		Transition._return_to_menu();
