extends CharacterBody2D
class_name LadderBody2D

@onready var ladder_scene :LibraryLadder= get_parent()
@onready var ladder_sides :Node2D= %LadderSides

var resistance = 0.2
var max_speed = 500.0
var friction = 5.0
var recent_push_strength:float

var slide_duration:float=0.0

func _ready() -> void:
	friction = ladder_scene.rail_friction
	resistance = ladder_scene.resistance
	max_speed = ladder_scene.max_speed


func _physics_process(delta: float) -> void:
	velocity.y=0.0
	velocity.x*=1-delta*friction
	
	if abs(velocity.x) > 5.0:
		slide_duration+=delta
	else:
		slide_duration=0.0
	
	if position.x <= (ladder_scene.rail_left.position.x+115.0):
		if slide_duration > 0.3:
			velocity.x = abs(velocity).x*0.4
		else:
			velocity.x = maxf(velocity.x,10.0)
	elif position.x >= (ladder_scene.rail_right.position.x-115.0):
		if slide_duration > 0.3:
			velocity.x = -abs(velocity).x*0.4
		else:
			velocity.x = minf(velocity.x,-10.0)
	move_and_slide()
	ladder_sides.position=position
	#_push_rigid_bodies()

#func _push_rigid_bodies() -> void:
	#for i in get_slide_collision_count():
		#var collision = get_slide_collision(i)
		#var collider = collision.get_collider()
		#if collider is RigidBody2D:
			#recent_push_strength = collider.linear_velocity.x*(1.0-resistance)*abs(collision.get_normal().x)
			#print("push strength: ",recent_push_strength)
