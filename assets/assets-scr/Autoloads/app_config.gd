extends Node # app_config.gd

func _ready():
	GlobalState.open()
	AppSettings.set_from_config_and_window(get_window())
