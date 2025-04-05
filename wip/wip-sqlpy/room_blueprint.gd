class_name TowerRoom
extends Node2D

@export var camera_static : bool = true
@export var start_room : bool = false
@export_category("Connections")
@export var left_room : TowerRoom
@export var right_room : TowerRoom
@export var up_room : TowerRoom
@export var down_room : TowerRoom

@onready var camera_target: Marker2D = $CameraTarget
@onready var camera_bounds: ReferenceRect = $CameraBounds

var left_room_door: RoomDoor
var right_room_door: RoomDoor
var up_room_door: RoomDoor
var down_room_door: RoomDoor


func _ready() -> void:
	if start_room:
		SignalBus.room_changed.emit(self)
	for child in get_children(true):
		if child.name == "UpRoomDoor":
			up_room_door = child
		if child.name == "DownRoomDoor":
			down_room_door = child
		if child.name == "RightRoomDoor":
			right_room_door = child
		if child.name == "LeftRoomDoor":
			left_room_door = child

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	_check_room_transition()
	if not camera_static:
		_adjust_camera_target()
		

func _check_room_transition() -> void:
	var player : Node2D = GlobalVars.player
	var closest_door : RoomDoor = RoomDoor.get_closest_door_to_player()
	if closest_door == null:
		return
	if closest_door == left_room_door:
		SignalBus.room_changed.emit(left_room)
	if closest_door == right_room_door:
		SignalBus.room_changed.emit(right_room)
	if closest_door == down_room_door:
		SignalBus.room_changed.emit(down_room)
	if closest_door == up_room_door:
		SignalBus.room_changed.emit(up_room)

func _adjust_camera_target() -> void:
	var player : Node2D = GlobalVars.player
	camera_target.global_position = Util.clamp_point_to_rect(player.global_position, camera_bounds.get_global_rect())
