extends Camera2D

@export_range(0.1, 30.0, 0.1) var convergence_speed : float

func _process(delta: float) -> void:
	var current_room : TowerRoom = GlobalVars.current_room
	if current_room != null:
		global_position = Util.delta_lerp_vec2(global_position, current_room.camera_target.global_position, convergence_speed, delta)
