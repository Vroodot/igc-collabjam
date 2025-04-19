extends RigidBody2D
class_name PouncePlayer2D

signal harmed()
signal healed()
signal died()

@export var interaction_detect: InteractionDetector
@export var animation_player: AnimationPlayer
@export var visual_component :Node2D
@export_group("Stats")
@export var HEALTH_MAX: int = 9
@export var move_force :float= 6600.0
@export var jump_impulse_strength :float=5700.0
@export_range(30.0,60.0,1.0) var slope_angle_max :float= 45.0 ##How far the char's rotation can adjust to slopes[br]In degrees, but will be converted into rads inside of _ready()
@export_range(0.0,3.0,0.1) var rotation_stabilizer :float= 1.0 ##How much angualar force should be applied to correct the current rotation
@export_group("Pounce Controls")
@export_range(0.2,4.0,0.05) var charge_time :float= 1.0 ##in seconds (until charge is full)
##[b]Left/Right: [/b] Left and right keys control rotation[br][br]
##[b]Up/Down: [/b] Up and down keys control rotation[br][br]
##[b]Mouse targeting: [/b] the cat looks at the mouse position (rotation is still clamped between min and max values)[br][br]
##[b]Mouse delta: [/b] moving the mouse up or down changes rotation. This also enables MOUSE_MODE_CAPTURED to avoid the cursor leaving the screen[br][br]
##[b]Mouse delta XY: [/b] same as above, but moving the mouse left or right has the same effect (which axis wins out depends on which one has the higher delta)[br][br]
##[b]Mouse Left/Right: [/b] Left and right mouse clicks control rotation[br][br]
##[b]Charged Targeting: [/b] Rotation angles upwards automatically as charge increases. Combine with "charge_always_full" to limit the charge's impact to the rotation
@export_enum("Left/Right", "Up/Down", "Mouse Targeting", "Mouse Delta", "Mouse Delta XY", "Mouse Left/Right", "Charged Targeting") var pounce_control_type :int=0
@export var charge_always_full :bool = false ##If checked, pounce will always assume use maximum force
@export_range(0.0,0.7) var min_jump_charge :float = 0.3 ##Charge starts at this fraction of jump force
@export_range(0.1,0.9,0.05) var h_jump_control :float= 0.7 ##Multiplied with movement speed while airborne
@export_range(0.1,3.0) var landing_boost :float = 0.75 ##Factor that will be added on top of the character's speed upon landing a jump
@export_range(0.1,4.0) var landing_boost_duration :float = 0.5 ##Duration in seconds of the character's speed boost upon landing
@export_range(45,180.0,5.0) var pounce_aim_speed :float = 130.0 ##Aiming speed in Degrees per Second
@export_range(5.0,40.0,0.5) var min_pounce_angle :float = 15.0
@export_range(5.0,90.0,0.5) var def_pounce_angle :float = 45.0
@export_range(50.0,90.0,0.5) var max_pounce_angle :float = 85.0

@onready var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
@onready var ground_detect_left: RayCast2D = %GroundDetectLeft
@onready var ground_detect_right: RayCast2D = %GroundDetectRight


var health = HEALTH_MAX
var respawn_position = global_position

var get_pounce_rotation_input :Callable
var default_gravity_scale :float = self.gravity_scale
var on_floor :bool=false
var on_wall :bool=false
var neutral_force :Vector2
var jump_charge :float=min_jump_charge
var current_movement_boost :float=0.0
var pounce_rotation :float=0.0

func _ready() -> void:
	GlobalVars.player = self
	
	#push errrors if exported references haven't been assigned
	if !visual_component:
		push_error("No visual component assigned in player script ", self)
	if !interaction_detect:
		push_error("No interaction detector assigned in player script ", self)
	if !animation_player:
		push_error("No animation player assigned in player script ", self)
	
	#calculate gravity-neutralizing constant force 
	neutral_force = Vector2(0.0,gravity*default_gravity_scale*-3.1)
	#neutral force negated becomes gravity, necessary for later rotation
	constant_force = neutral_force + neutral_force*-1
	#change degrees to radians for more efficient code
	slope_angle_max = deg_to_rad(slope_angle_max)
	#convert values from seconds to fractions
	charge_time = 1/charge_time
	landing_boost_duration = 1/landing_boost_duration
	#assign callable for pounce rotation input
	match pounce_control_type:
		0:
			get_pounce_rotation_input = pounce_rotation_left_right
		1:
			get_pounce_rotation_input = pounce_rotation_up_down
		2:
			get_pounce_rotation_input = pounce_rotation_mouse_targeting
		3:
			get_pounce_rotation_input = pounce_rotation_mouse_delta
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		4:
			get_pounce_rotation_input = pounce_rotation_mouse_delta_xy
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		5:
			get_pounce_rotation_input = pounce_rotation_mouse_left_right
		6:
			get_pounce_rotation_input = pounce_rotation_charge_targeting

var previous_velocity:Vector2=Vector2.ZERO
##Handles wall/floor detection
func _integrate_forces(state: PhysicsDirectBodyState2D):
	on_floor = false
	on_wall = false
	var on_ladder :bool=false
	for i in range(state.get_contact_count()): 
		if abs(state.get_contact_local_normal(i).angle_to(Vector2.UP)) <= (slope_angle_max*1.2):
			on_floor = true
			if state.get_contact_collider_object(i) is LadderBody2D:
				#HACK this is a terrible workaround to make prevent the player from pushing a library ladder while standing on it
				on_ladder = true
		else:
			on_wall = true
			
			var collision_object = state.get_contact_collider_object(i) 
			if (!on_ladder) and collision_object is LadderBody2D:
				if abs(state.get_contact_local_normal(i).angle_to(previous_velocity))>(PI*0.5):
					if abs(previous_velocity.x) > 100:
						collision_object.velocity.x = clampf(previous_velocity.x*mass*(1-collision_object.resistance),-collision_object.max_speed,collision_object.max_speed)
	set_previous_velocity.call_deferred()


func _physics_process(delta: float) -> void:
	
	## Allows for Esc key to release cursor
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED)
	elif Input.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	#declare force and set movement direction
	var force :Vector2 = Vector2.ZERO
	force.x = Input.get_axis("left", "right")
	
	#play animation
	if !is_zero_approx(force.x):
		if !animation_player.is_playing():
			animation_player.play(&"TestLibrary/anim_walk_test")
	else:
		if animation_player.is_playing():
			animation_player.play(&"RESET")
	
	#sets rotation target for gravity changes and rotation stabilizer
	var rotation_target = clampf(calculate_avg_ground_normal(force.x*-10),-slope_angle_max,slope_angle_max)
	
	#reset gravity
	gravity_scale = default_gravity_scale
	
	#changes movement and gravity depending on floor/ground detection
	if !on_floor:
		constant_force = neutral_force + neutral_force*-1
		if linear_velocity.y > 0.0: #falling
			force.x *= h_jump_control #reduce movement speed while airborne
		else: #jumping
			force.x *= h_jump_control*0.8
		if on_wall: #slow down gravity while hanging on wall
			gravity_scale = default_gravity_scale * 0.7
	else: #rotates gravity and tunes it down a little while on floor
		constant_force = 0.4*(-neutral_force).rotated(rotation_target) + neutral_force 
		current_movement_boost = max(current_movement_boost-landing_boost*landing_boost_duration*delta, 0.0)
	
	#Rotates towards the rotation target
	if rotation > (rotation_target+0.1):
		apply_torque(-5010.1*rotation_stabilizer)
	elif rotation < (rotation_target-0.1):
		apply_torque(5010.1*rotation_stabilizer)
	
	
	#jump input handling
	if on_floor and Input.is_action_pressed("pounce"):
		if abs(pounce_rotation) < min_pounce_angle:
			pounce_rotation = def_pounce_angle*-visual_component.scale.x
		pounce_rotation = get_pounce_rotation_input.call(delta)
		force.x = 0.0
		jump_charge = minf(jump_charge+charge_time*delta,1.0)
		visual_component.scale.y = 1.0-jump_charge*0.4
		update_visual_to_pounce_rotation()
	if on_floor and Input.is_action_just_released("pounce"):
		visual_component.scale.y = 1.0
		#using the visual's scale.x to determine character direction
		if charge_always_full:
			jump_charge = 1.0
		apply_impulse(Vector2.UP.rotated((PI*0.5-abs(visual_component.rotation))*visual_component.scale.x)*jump_impulse_strength*jump_charge)
		current_movement_boost = landing_boost*jump_charge
		jump_charge = min_jump_charge
		pounce_rotation = 0.0
		update_visual_to_pounce_rotation()
	
	if on_floor and Input.is_action_just_pressed(&"jump") and !Input.is_action_pressed("pounce"):
		apply_impulse(Vector2.UP.rotated(rotation_target*0.4)*jump_impulse_strength*0.52)
		jump_charge = min_jump_charge
		pounce_rotation = 0.0
		update_visual_to_pounce_rotation()
		current_movement_boost = landing_boost*0.5
	#Flips assigned 2D visuals
	if on_floor and ((current_movement_boost<0.01)or(linear_velocity.y < 1.0)) and !Input.is_action_just_released("jump"): #only change sprite direction while jump isn't charging!
		if force.x < -0.1:
			visual_component.scale.x = -1.0
		elif force.x > 0.1:
			visual_component.scale.x = 1.0
	
	#applied movement speed, rotates by ground normal and moves character
	force.x *= move_force*(1.0+current_movement_boost)
	force = force.rotated(rotation_target) 
	apply_force(force)

##Reduces health and emits harmed signal
func take_damage(amount: int) -> void:
	if amount <= 0: 
		printerr("You can't take negative damage")
	health -= amount
	harmed.emit()
	if health <= 0:
		health = 0
		die()
	prints(self.name, health)

##Increases health up to HEALTH_MAX and emits healed signal
func heal(amount: int) -> void:
	if amount <= 0:
		printerr("You can't heal a negative amount")
	health += amount
	healed.emit()
	if health >= HEALTH_MAX:
		health = HEALTH_MAX
	prints(self.name, health)

##Emits died signal, heals the player back up and resets location
func die() -> void:
	died.emit()
	global_position = respawn_position
	print("Well you should be dead, but vrood didn't get there so here have nine more lives!!")
	heal(9)

##Gets the average collision normal from all three ground raycasts
func calculate_avg_ground_normal(weigh_side:float=0.0)->float:
	var avg_angle:float=0.0
	if ground_detect_left.is_colliding():
		avg_angle += ground_detect_left.get_collision_normal().angle_to(Vector2.UP)*(-1)*minf(-1+weigh_side, -1.0)
	if ground_detect_right.is_colliding():
		avg_angle += ground_detect_right.get_collision_normal().angle_to(Vector2.UP)*maxf(1+weigh_side, 1.0)
	avg_angle -= rotation
	avg_angle /= 3+abs(weigh_side)
	return -avg_angle

##Aims pounce with the left and right inputs
func pounce_rotation_left_right(delta:float) -> float:
	var input = Input.get_axis("left", "right") *delta *pounce_aim_speed
	if visual_component.scale.x > 0.0:
		return clampf(pounce_rotation+input,-max_pounce_angle,-min_pounce_angle)
	else:
		return clampf(pounce_rotation+input,min_pounce_angle,max_pounce_angle)

##Aims pounce with the up and down inputs
func pounce_rotation_up_down(delta:float) -> float:
	var input = Input.get_axis("up", "down") *visual_component.scale.x *delta *pounce_aim_speed
	if visual_component.scale.x > 0.0:
		return clampf(pounce_rotation+input,-max_pounce_angle,-min_pounce_angle)
	else:
		return clampf(pounce_rotation+input,min_pounce_angle,max_pounce_angle)

##Aims pounce by rotation towards the current cursor location
func pounce_rotation_mouse_targeting(delta:float) -> float:
	var rot_to_cursor = -get_local_mouse_position().angle_to(Vector2.RIGHT*visual_component.scale.x)
	#rot_to_cursor = lerp_angle(visual_component.rotation, rot_to_cursor, 1.0 - exp(-3.1 * delta)) #Util.delta_lerp(visual_component.rotation, rot_to_cursor, 10.1, delta)
	rot_to_cursor = rad_to_deg(rot_to_cursor)
	
	if visual_component.scale.x > 0.0:
		return clampf(rot_to_cursor,-max_pounce_angle,-min_pounce_angle)
	else:
		return clampf(rot_to_cursor,min_pounce_angle,max_pounce_angle)

##Aims pounce by rotating with mouse movement
func pounce_rotation_mouse_delta(delta:float) -> float:
	return 0.0
func pounce_rotation_mouse_delta_xy(delta:float) -> float:
	return 0.0

##Aims pounce with the left and right mouse buttons
func pounce_rotation_mouse_left_right(delta:float) -> float:
	var input :float = 0.0
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		input -= 1.0
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		input += 1.0
	input *=  delta *pounce_aim_speed
	if visual_component.scale.x > 0.0:
		return clampf(pounce_rotation+input,-max_pounce_angle,-min_pounce_angle)
	else:
		return clampf(pounce_rotation+input,min_pounce_angle,max_pounce_angle)

##Aims pounce upwards with jump charge
func pounce_rotation_charge_targeting(delta:float) -> float:
	var input :float= (jump_charge-min_jump_charge+0.001)/(1-min_jump_charge)
	print((1-min_jump_charge), " ::: ", (jump_charge-min_jump_charge), " :results in: ", input)
	if visual_component.scale.x > 0.0:
		return rad_to_deg(lerp_angle(deg_to_rad(-min_pounce_angle),deg_to_rad(-max_pounce_angle),input))
	else:
		return rad_to_deg(lerp_angle(deg_to_rad(min_pounce_angle),deg_to_rad(max_pounce_angle),input))



func update_visual_to_pounce_rotation():
	visual_component.rotation_degrees = pounce_rotation


func set_previous_velocity():
	previous_velocity=linear_velocity
