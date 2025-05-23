class_name RoomController
extends Node

@export var enable_and_disable_rooms : bool = false
@export var print_room_transitions_to_console : bool = false

var rooms: Array = []

func _ready() -> void:
	SignalBus.room_changed.connect(_on_room_changed)
	SignalBus.register_room.connect(_on_room_registered)
	SignalBus.tower_ready.connect(_on_tower_ready)

func _on_tower_ready() -> void:
	_update_room_status()

func _on_room_registered(room: TowerRoom) -> void:
	rooms.append(room)

func _on_room_changed(target_room: TowerRoom) -> void:
	if not target_room:
		print("Target room not found")
		return
	if target_room != GlobalVars.current_room:
		if print_room_transitions_to_console and GlobalVars.current_room:
			prints("Room transition triggered from", GlobalVars.current_room.name, "to", target_room.name)
		GlobalVars.current_room = target_room
		_update_room_status()

func _update_room_status() -> void:
	var active_rooms: Array = _get_active_rooms(GlobalVars.current_room)
	if enable_and_disable_rooms:
		for room in rooms:
			room.disable()
		for room in active_rooms:
			room.enable()

func _get_active_rooms(target_room: TowerRoom) -> Array:
	var active_rooms: Array = [target_room]
	active_rooms.append_array(target_room.adjacent_rooms)
	return active_rooms
