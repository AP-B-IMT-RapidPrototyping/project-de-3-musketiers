extends CharacterBody3D

var speed := 4.0
@export var look_sensitivity := 0.01
@export var fov := 75.0
@export var jump_velocity := 4.0
@export var can_jump := true

@export var camera_tilt_amount : float = 5
@export var weapon_sway_amount : float = 10
@export var weapon_rotation_amount : float = 1
@export var invert_weapon_sway : bool = false

@export var idle_bob_amount : float = 0.002
@export var idle_bob_freq : float = 0.002
@export var walk_bob_amount : float = 0.01
@export var walk_bob_freq : float = 0.01
@export var aim_bob_amount: float = 0.2
@export var aim_bob_freq : float = 0.2
var bob_amount : float = 0.01
var bob_freq : float = 0.01

@export var idle_sway_speed := 1.0
@export var idle_sway_amount := 1.0
@export var noise: FastNoiseLite

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var camera:Camera3D = $"Camera Holder/Camera3D"
@onready var camera_holder:Node3D = $"Camera Holder"
@onready var weapon_holder:Node3D = $"Camera Holder/Weapon Holder"
@onready var camera_aim:RayCast3D = $"Camera Holder/Camera3D/RayCast3D"
var current_weapon:Node3D
var weapon_index := 0
@onready var weapon_count := weapon_holder.get_child_count()
@onready var crosshairs:Control = $"Camera Holder/Camera3D/CanvasLayer/HUD/Crosshairs"

var def_weapon_holder_pos : Vector3
var mouse_input : Vector2
var time := 0.0
var health := 100
var dead := false

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	def_weapon_holder_pos = weapon_holder.position
	for w in weapon_holder.get_children():
		w.player = self
	switch_weapon()

func _physics_process(delta):
	# snelheid afhankelijk van aim
	if current_weapon.aiming:
		speed = current_weapon.aim_speed
	else:
		speed = current_weapon.normal_speed
	
	var input_vec := Input.get_vector("move_left","move_right","move_forward","move_backward").normalized()
	var b := global_transform.basis
	var move_dir := (b.x * input_vec.x + b.z * input_vec.y)
	velocity.x = move_dir.x * speed
	velocity.z = move_dir.z * speed
	
	if !is_on_floor():
		velocity.y -= gravity * delta
	elif can_jump and Input.is_action_just_pressed("jump"):
		velocity.y = jump_velocity
	
	move_and_slide()
	
	time += delta * idle_sway_speed
	
	var idle_sway_x := 0.0
	var idle_sway_y := 0.0
	if noise:
		idle_sway_x = sin(time * 1.5 + noise.get_noise_1d(time)) * idle_sway_amount
		idle_sway_y = sin(time - noise.get_noise_1d(time)) * idle_sway_amount
	
	camera.rotation.z = lerp(camera.rotation.z, -input_vec.x * deg_to_rad(camera_tilt_amount), 10 * delta)
	weapon_holder.rotation.z = lerp(weapon_holder.rotation.z, -input_vec.x * deg_to_rad(weapon_rotation_amount), 10 * delta)
	weapon_holder.rotation.x = lerp(weapon_holder.rotation.x, input_vec.y * deg_to_rad(weapon_rotation_amount) / 2.0, 10 * delta)
	
	weapon_holder.rotation.y = lerp_angle(weapon_holder.rotation.y, deg_to_rad(mouse_input.x) + deg_to_rad(idle_sway_x), delta * 10)
	weapon_holder.rotation.x = lerp_angle(weapon_holder.rotation.x, deg_to_rad(mouse_input.y) + deg_to_rad(idle_sway_y), delta * 10)
	
	var height_offset := 0.0
	if current_weapon.reloading:
		height_offset = current_weapon.height_offset
	if current_weapon.aiming:
		current_weapon.position = lerp(current_weapon.position, current_weapon.aim_pos, delta * 10)
		camera.fov = lerp(camera.fov, fov / current_weapon.zoom, delta * 10)
	else:
		current_weapon.position = lerp(current_weapon.position, current_weapon.def_pos, delta * 10)
		camera.fov = lerp(camera.fov, fov, delta * 10)
	current_weapon.rotation.z = lerp(current_weapon.rotation.z, 0.0, delta * 10)
	current_weapon.rotation.y = lerp(current_weapon.rotation.y, deg_to_rad(90), delta * 10)
	
	if velocity.length() == 0 or !is_on_floor():
		bob_amount = idle_bob_amount
		bob_freq = idle_bob_freq
	else:
		bob_amount = walk_bob_amount
		bob_freq = walk_bob_freq
	if current_weapon.aiming:
		bob_amount *= aim_bob_amount
	
	var t := Time.get_ticks_msec() / 1000.0
	weapon_holder.position.y = lerp(weapon_holder.position.y, def_weapon_holder_pos.y + sin(t * bob_freq) * bob_amount - height_offset, 10 * delta)
	weapon_holder.position.x = lerp(weapon_holder.position.x, def_weapon_holder_pos.x + sin(t * bob_freq * 0.5) * bob_amount, 10 * delta)
	
	if camera_aim.is_colliding():
		current_weapon.muzzle.look_at(camera_aim.get_collision_point())
	
	if !current_weapon.shooting and !current_weapon.reloading:
		if Input.is_action_just_pressed("next_weapon"):
			if weapon_index == weapon_count - 1:
				weapon_index = 0
			else:
				weapon_index += 1
			switch_weapon()
		elif Input.is_action_just_pressed("previous_weapon"):
			if weapon_index == 0:
				weapon_index = weapon_count - 1
			else:
				weapon_index -= 1
			switch_weapon()
	
	current_weapon.aiming = Input.is_action_pressed("aim") and !current_weapon.reloading
	if Input.is_action_just_pressed("reload"):
		current_weapon.reload()
	if Input.is_action_just_pressed("shoot"):
		current_weapon.start_shooting()
	elif Input.is_action_just_released("shoot"):
		current_weapon.stop_shooting()

func recoil(amount:Vector2, camera_shake:float, z_pos:float):
	if camera.has_method("set_min_trauma"):
		camera.set_min_trauma(camera_shake)
	var y_recoil = deg_to_rad(randf_range(-amount.x, amount.x))
	var x_recoil = deg_to_rad(amount.y)
	current_weapon.rotate_y(y_recoil)
	current_weapon.rotate_x(x_recoil)
	rotate_y(y_recoil)
	camera_holder.rotate_x(x_recoil / 5.0)
	camera_holder.rotation.x = clamp(camera_holder.rotation.x, -PI/2, PI/2)
	current_weapon.position.z = z_pos

func _input(event):
	if event is InputEventMouseMotion:
		var ls = look_sensitivity
		if current_weapon.aiming:
			ls = current_weapon.look_sensitivity
		rotate_y(event.relative.x * -ls)
		camera_holder.rotate_x(event.relative.y * -ls)
		camera_holder.rotation.x = clamp(camera_holder.rotation.x, -PI/2, PI/2)
		mouse_input = clamp(
			event.relative,
			Vector2(-weapon_sway_amount, -weapon_sway_amount) / 2.0,
			Vector2(weapon_sway_amount, weapon_sway_amount) / 2.0
		)

func switch_weapon():
	for i in range(weapon_count):
		var weapon = weapon_holder.get_child(i)
		var cross = crosshairs.get_child(i)

		weapon.visible = i == weapon_index
		cross.visible = i == weapon_index

		if i == weapon_index:
			weapon.process_mode = PROCESS_MODE_INHERIT
		else:
			weapon.process_mode = PROCESS_MODE_DISABLED

	current_weapon = weapon_holder.get_child(weapon_index)
	current_weapon.update_ammo()

	if Input.is_action_pressed("aim"):
		current_weapon.position = current_weapon.aim_pos
	else:
		current_weapon.position = current_weapon.def_pos

func take_damage(amount:float):
	if dead:
		return
	health = max(health - amount, 0)
	$"Camera Holder/Camera3D/CanvasLayer/HUD/Health Bar".value = health
	if health == 0:
		$"04_DeathGroan(male)".play()
		dead = true
		$CollisionShape3D.disabled = true
		velocity = Vector3.ZERO
		get_tree().reload_current_scene()
	else:
		$"02_DamageGrunt(male)".play()
