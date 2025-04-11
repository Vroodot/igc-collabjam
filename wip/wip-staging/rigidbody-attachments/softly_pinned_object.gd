class_name SoftPin
extends Node

@export var lock_horizontal: bool = false
@export var lock_vertical: bool = false
@export_range(0.0, 1.0, 0.01) var horizontal_stiffness: float = 1.0
@export_range(0.0, 1.0, 0.01) var vertical_stiffness: float = 1.0
@export_range(0.0, 20.0) var damp_override : float = 5.0

@export var linear_stiffness: float = 1000.0
@export var quadratic_stiffness: float = 0.1

@export var soft_nax_distance: float = 50.0
@export var hard_max_distance: float = 100.0

var parent: RigidBody2D
var reference_position: Vector2

func _ready() -> void:
	parent = get_parent()
	if damp_override > 0.01:
		parent.linear_damp = damp_override
	parent.lock_rotation = true
	reference_position = parent.global_position

func _physics_process(delta: float) -> void:
	var current_position: Vector2 = parent.global_position
	var displacement: Vector2 = current_position - reference_position

	if lock_horizontal:
		parent.global_position.x = reference_position.x
		parent.linear_velocity.x = 0
	if lock_vertical:
		parent.global_position.y = reference_position.y
		parent.linear_velocity.y = 0

	var distance: float = displacement.length()
	var direction: Vector2 = displacement.normalized()

	if distance > hard_max_distance:
		parent.global_position = reference_position + direction * hard_max_distance
		distance = hard_max_distance
		parent.linear_velocity.x = 0
		parent.linear_velocity.y = 0

	var effective_distance: float = min(distance, soft_nax_distance)
	var force: Vector2 = -linear_stiffness * effective_distance * direction

	if distance > soft_nax_distance:
		var extra_distance: float = distance - soft_nax_distance
		force += -quadratic_stiffness * extra_distance * extra_distance * direction

	# Apply directional stiffness to each component separately
	force.x *= horizontal_stiffness
	force.y *= vertical_stiffness

	parent.apply_central_force(force)
