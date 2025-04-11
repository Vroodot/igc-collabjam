extends CharacterBody2D


const SPEED = 300.0
const JUMP_VELOCITY = -400.0
var push_force = 80.0
@export var mass : float = 2.0
@onready var cat_sprite: Sprite2D = $CatSprite

func _ready() -> void:
	GlobalVars.player = self

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_axis("left", "right")
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()
	if abs(velocity.x) > 0:
		if velocity.x > 0:
			cat_sprite.flip_h = true
		else:
			cat_sprite.flip_h = false
	_push_rigid_bodies()

func _push_rigid_bodies() -> void:
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		if collider is RigidBody2D:
			var normal = collision.get_normal()
			var push_strength = max(-velocity.dot(normal), 1) * push_force 
			var force = -normal * push_strength
			collider.apply_central_force(force)
