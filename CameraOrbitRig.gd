extends Node3D
# Single-camera rig that:
# - Pans with the right stick (±max_side_deg)
# - Auto flips to the front (180°) while reversing, and back behind when driving forward

@export var max_side_deg := 90.0      # how far to peek left/right
@export var deadzone := 0.25          # stick must pass this to start peeking
@export var recenter_zone := 0.15     # recentre when below this
@export var stick_curve := 1.4        # >1 gives finer control near centre

@export var pan_smooth := 10.0        # speed to pan side-to-side
@export var flip_smooth := 6.0        # speed to flip 0°↔180°
@export var reverse_threshold := 1.2  # m/s along car forward to decide reversing
@export var invert_axis := false      # swap if left/right feels reversed

var _side_target := 0.0               # radians (-max..+max)
var _base_yaw_cur := 0.0              # 0 = behind, PI = front
var _is_reversing := false

func _physics_process(delta: float) -> void:
	var car := get_parent() as RigidBody3D
	if car == null:
		return

	# --- 1) Decide reversing vs forward (uses longitudinal velocity) ---
	var fwd := -car.global_transform.basis.z
	var long_speed := car.linear_velocity.dot(fwd) # + = forward, - = backward

	# hysteresis to avoid flicker around zero
	if _is_reversing:
		if long_speed > reverse_threshold * 0.5:
			_is_reversing = false
	else:
		if long_speed < -reverse_threshold:
			_is_reversing = true

	var base_target := PI if _is_reversing else 0.0
	_base_yaw_cur = lerp_angle(_base_yaw_cur, base_target, clamp(flip_smooth * delta, 0.0, 1.0))

	# --- 2) Read right stick X (actions) + optional keyboard fallback ---
	var axis := Input.get_action_strength("cam_right_axis_pos") \
			  - Input.get_action_strength("cam_right_axis_neg")

	if invert_axis:
		axis = -axis

	if axis == 0.0:
		if Input.is_action_pressed("cam_peek_right"):
			axis = 1.0
		elif Input.is_action_pressed("cam_peek_left"):
			axis = -1.0

	# Deadzone + response curve
	if abs(axis) < deadzone:
		if abs(axis) < recenter_zone:
			_side_target = 0.0
	else:
		var shaped: float = sign(axis) * pow(abs(axis), stick_curve)
		_side_target = deg_to_rad(max_side_deg) * shaped

	# --- 3) Apply combined yaw (base + side peek) smoothly ---
	var yaw_target := _base_yaw_cur + _side_target
	rotation.y = lerp_angle(rotation.y, yaw_target, clamp(pan_smooth * delta, 0.0, 1.0))
