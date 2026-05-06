extends Node3D

@export var useable := true
@export var price := 500
@export var shoot_range := 50
@export var damage := 20.0
@export var fire_rate := 0.1
@export var mag_size := 30
@export var reload_time := 3.0
@export var spread := 1.0
@export var auto := true
@export var bullet_count := 1
@export var bullet_hole_time := 2.5

@export var normal_recoil := Vector2(2, 5)
@export var aim_recoil := Vector2(1, 2)
@export var camera_shake : float = 0.3

@export var look_sensitivity = 0.005
@export var zoom = 1.5
@export var normal_speed = 4.0
@export var aim_speed = 2.0
var def_pos:Vector3
@export var aim_pos:Vector3
@export var height_offset := 0.1

var firing := false
var shooting := false
var can_shoot := true
var reloading := false
var aiming := false
var bullets := 30

@onready var muzzle = $Muzzle

var shot_sound := preload("res://Sound/gunshot_16.ogg")
var bullet_hole := preload("res://bullet_hole.tscn")

var player:CharacterBody3D

func _ready() -> void:
	if !useable:
		hide()
		process_mode = ProcessMode.PROCESS_MODE_DISABLED

	def_pos = position
	shoot_range *= 50
	bullets = mag_size

	# Create RayCast3D bullets
	for i in range(bullet_count):
		var ray = RayCast3D.new()
		muzzle.add_child(ray)
		ray.rotation.x = deg_to_rad(randf_range(-spread, spread))
		ray.rotation.y = deg_to_rad(randf_range(-spread, spread))

	# Only apply target_position to RayCast3D nodes
	for x in muzzle.get_children():
		if x is RayCast3D:
			x.target_position = Vector3(0, 0, -shoot_range)

func shoot():
	if !can_shoot or reloading:
		$Gunempty.play()
		return

	if aiming:
		player.recoil(aim_recoil, camera_shake, def_pos.z + 0.02)
	else:
		player.recoil(normal_recoil, camera_shake, aim_pos.z + 0.05)

	play_shot_sound()
	muzzle.emitting = true
	bullets -= 1

	# Randomize bullet spread
	for i in range(bullet_count):
		if muzzle.get_child_count() > i:
			var ray = muzzle.get_child(i)
			ray.rotation.x = deg_to_rad(randf_range(-spread, spread))
			ray.rotation.y = deg_to_rad(randf_range(-spread, spread))

	# Collision detection
	for x in muzzle.get_children():
		if x is RayCast3D and x.is_colliding():
			var col = x.get_collider()
			if col.has_method("take_damage"):
				col.take_damage(damage)
			else:
				var hole = bullet_hole.instantiate()
				get_tree().root.add_child(hole)
				hole.position = x.get_collision_point()
				hole.look_at(x.get_collision_point() + x.get_collision_normal())
				hole.rotate_object_local(Vector3(1, 0, 0), 90)
				destroy_bullet_hole(hole)

	can_shoot = auto and bullets > 0
	update_ammo()

	if !can_shoot or !shooting or reloading:
		return

	firing = true
	await get_tree().create_timer(fire_rate).timeout
	firing = false

	if can_shoot and shooting and !reloading:
		shoot()

func update_ammo():
	$"../../Camera3D/CanvasLayer/HUD/Ammo".text = str(bullets) + "/" + str(mag_size)

func start_shooting():
	if shooting or reloading:
		return
	can_shoot = bullets > 0
	shooting = true
	shoot()

func stop_shooting():
	if !shooting or reloading:
		return
	can_shoot = bullets > 0
	shooting = false

func reload():
	can_shoot = false
	shooting = false
	reloading = true
	$Reload.play()
	await get_tree().create_timer(reload_time).timeout
	bullets = mag_size
	update_ammo()
	reloading = false
	can_shoot = true

func destroy_bullet_hole(hole:Decal):
	await get_tree().create_timer(bullet_hole_time).timeout
	hole.queue_free()

func play_shot_sound():
	var sound = AudioStreamPlayer.new()
	sound.volume_db = -10
	sound.stream = shot_sound
	add_child(sound)
	sound.play()
	await get_tree().create_timer(shot_sound.get_length()).timeout
	sound.queue_free()
