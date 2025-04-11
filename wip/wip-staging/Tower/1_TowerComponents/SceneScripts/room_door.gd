@tool
class_name RoomDoor
extends Node2D

@export_range(1.0, 500.0, 1.0) var door_size: float = 48.0: set = set_door_size
@export_enum("⇆", "⇅") var door_direction : int = 0: set = set_door_direction
@export var orange_room: TowerRoom
@export var green_room: TowerRoom

@onready var orange_area: RoomDoorArea = %Orange
@onready var green_area: RoomDoorArea = %Green
@onready var door_collision_shape: CollisionShape2D = %DoorShape

func _ready() -> void:
	if Engine.is_editor_hint(): return
	if not orange_room or not green_room:
		printerr("Door", name, " is missing at least one connection to a valid room")
		queue_free()
		return
	green_area.set_target_room(green_room)
	orange_area.set_target_room(orange_room)
	green_room.adjacent_rooms.append(orange_room)
	orange_room.adjacent_rooms.append(green_room)

func set_door_size(size: float) -> void:
	if Engine.is_editor_hint():
		if door_direction == 0:
			door_collision_shape.shape.size.y = door_size
			door_collision_shape.shape.size.x = 32
		else:
			door_collision_shape.shape.size.x = door_size
			door_collision_shape.shape.size.y = 32
	door_size = size

func set_door_direction(type : int) -> void:
	if Engine.is_editor_hint():
		if door_direction == 1:
			orange_area.position = Vector2(-16, 0)
			green_area.position  = Vector2( 16, 0)
			door_collision_shape.shape.size.x = 32
			door_collision_shape.shape.size.y = door_size
		else:
			orange_area.position = Vector2(0, -16)
			green_area.position  = Vector2(0,  16)
			door_collision_shape.shape.size.x = door_size
			door_collision_shape.shape.size.y = 32
	door_direction = type
		
