extends VehicleBody3D

const MAX_STEER = 0.8
const ENGINE_POWER = 300

@export var camera_pivot: Node3D
@export var camera_3d: Camera3D
@export var reverse_camera: Camera3D

var look_at

func _ready():
	#Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	look_at = global_position
	pass

func _physics_process(delta):
	# Calculate steering based on input
	var steer_input = Input.get_axis("ui_right", "ui_left")
	steering = move_toward(steering, steer_input * MAX_STEER, delta * 2.5)

	# Calculate engine force based on input
	engine_force = Input.get_axis("brake", "accelerate") * ENGINE_POWER
	
	# Smoothly move the camera pivot point towards the global position of the vehicle body
	camera_pivot.global_position = camera_pivot.global_position.lerp(global_position, delta * 20)

	# Smoothly interpolate the camera pivot's transformation (position, rotation, scale) towards the vehicle body's transformation
	#camera_pivot.transform = camera_pivot.transform.interpolate_with(transform, delta * 5)

	
	#look_at = look_at.lerp(global_position + linear_velocity, delta * 5.0)
	camera_3d.look_at(look_at)
	#reverse_camera.look_at(look_at)
	#_check_camera_switch()
