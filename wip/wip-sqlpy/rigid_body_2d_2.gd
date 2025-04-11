extends RigidBody2D


func _physics_process(delta: float) -> void:
	apply_central_force(global_position.direction_to(get_global_mouse_position()) * 1000 * global_position.distance_to(get_global_mouse_position()))
