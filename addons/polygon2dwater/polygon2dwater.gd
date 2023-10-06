@tool
extends Node2D

@export var simulate_water: bool = true 
@export var WATER_COLOR = Color(1.0, 1.0, 1.0, 1.0)
@export var TOP_WATER_COLOR = Color(1.0, 1.0, 1.0, 1.0)
@export_range(0, 1) var particles_alpha: float = 0.5
@export var audio_splash: AudioStream = preload("res://addons/polygon2dwater/splash.ogg")
@export var HEIGHT: float = 0
@export var WIDTH: float = 0
@export var RESOLUTION: float = 15
@export var TENSION: float = 0.025
@export var DAMPING: float = 0.001
@export var PASSES: int = 1
@export var DISPERSION: float = 0.01
@export var water_distortion:int = 3
@export var emit_particles: bool = true
@export var water_texture: Texture = preload("res://addons/polygon2dwater/water_texture.png")

var water_particles = preload("res://addons/polygon2dwater/particles.tscn")
var water_shader = preload("res://addons/polygon2dwater/water.gdshader")
var droplet_texture = preload("res://addons/polygon2dwater/droplets.png")
var timer_queuefree_droplets = Timer.new()

var refreshing = false
var initialized = false
var vecs_positions = []
var vecs_velocity = []
var left_vec = []
var right_vec = []

var randomizator = RandomNumberGenerator.new()
var water
var water_area_2d
var _col

func _ready():
	randomizator.randomize()
	if Engine.is_editor_hint() == false:
		create_water_block()
	set_process(true)
	#self.z_index = 4096
	
	timer_queuefree_droplets.wait_time = 1
	timer_queuefree_droplets.autostart = true
	timer_queuefree_droplets.connect("timeout", _on_timer_droplets_timeout)
	add_child(timer_queuefree_droplets)

func _on_timer_box_timeout():
	if Engine.is_editor_hint() == false:
		create_water_block()
		
func _on_timer_droplets_timeout():
	for d in get_tree().get_nodes_in_group("water_droplets"):
		await get_tree().create_timer(0.5).timeout
		if weakref(d).get_ref():
			d.queue_free()
		break

func _physics_process(delta):
	if refreshing: return
	if Engine.is_editor_hint() == false:
		_dynamic_physics()
	else:
		queue_redraw()
	
func _dynamic_physics():
	if !weakref(water).get_ref(): return
	
	for i in vecs_positions.size() - 2:
		var target_y = -HEIGHT - vecs_positions[i].y
		vecs_velocity[i] += (TENSION * target_y) - (DAMPING * vecs_velocity[i])
		vecs_positions[i].y += vecs_velocity[i]
		
		water.polygon[i] = vecs_positions[i]
	
	#Dispersion
	for i in vecs_positions.size() - 2:
		left_vec[i] = 0
		right_vec[i] = 0
	
	for j in PASSES:
		for i in vecs_positions.size() - 2:
			if i > 0:
				left_vec[i] = DISPERSION * (vecs_positions[i].y - vecs_positions[i - 1].y)
				vecs_velocity[i - 1] += left_vec[i]
			if i < vecs_positions.size() - 3:
				right_vec[i] = DISPERSION * (vecs_positions[i].y - vecs_positions[i + 1].y)
				vecs_velocity[i + 1] += right_vec[i]
		for i in vecs_positions.size() - 2:
			if i > 0:
				vecs_positions[i - 1].y += left_vec[i]
			if i < vecs_positions.size() - 3:
				vecs_positions[i + 1].y += right_vec[i]
		
func create_water_block():
	var water_block = Polygon2D.new()
	var water_area_2d = Area2D.new()
	var water_collision_polygon_2d = CollisionPolygon2D.new()
	
	var distance_beetween_vecs = WIDTH / RESOLUTION

	var vecs: PackedVector2Array = PackedVector2Array([])
	
	vecs.insert(0, Vector2(0, -HEIGHT))
	for i in RESOLUTION:
		vecs.insert(i+1, Vector2(distance_beetween_vecs * (i + 1),-HEIGHT))
	
	vecs.insert(RESOLUTION + 1, Vector2(WIDTH, 0))
	vecs.insert(RESOLUTION + 2, Vector2(0, 0))
	
	water_block.name = "water_base"
	water_block.polygon = []
	water_block.polygon = vecs
	water_block.color = WATER_COLOR
	
	water_collision_polygon_2d.polygon = []
	water_collision_polygon_2d.polygon = water_block.polygon

	if simulate_water:
		var new_material = ShaderMaterial.new()
		new_material.shader = water_shader
		new_material.set_shader_parameter("blue_tint", WATER_COLOR)
		new_material.set_shader_parameter("sprite_scale", Vector2(1,1))
		new_material.set_shader_parameter("scale_x", water_distortion)
		new_material.set_shader_parameter("parent_position", position)
		water_block.material = new_material

		if water_texture != null:
			water_block.texture = water_texture

		water_block.antialiased = true
		water_area_2d.name = "water_area"
		water_area_2d.add_to_group("water_area")
		
		water_collision_polygon_2d.name = "water_col"
		
		self.add_child(water_block)
		water_block.add_child(water_area_2d)
		water_area_2d.add_child(water_collision_polygon_2d)
	
		water_area_2d.connect("body_entered", body_emerged)
		water_area_2d.connect("body_exited", body_not_emerged)
	
	for i in water_block.polygon.size():
		vecs_positions.insert(i, water_block.polygon[i])
		vecs_velocity.insert(i, 0)
		left_vec.insert(i, 0)
		right_vec.insert(i, 0)
	
	water = $"./water_base"
	_col = $"./water_base/water_area/water_col"

func body_emerged(body):
	if (body is RigidBody2D) or (body is CharacterBody2D) or (body is StaticBody2D):
		
		var force_applied = 11 * 0.5

		if body is RigidBody2D:
			force_applied = body.linear_velocity.y * 0.01
		
		var body_pos = body.position.x - self.position.x
		var closest_vec_pos_x = 9999999
		var closest_vec = 0

		for i in vecs_positions.size() - 2:
			var distance_diference = vecs_positions[i].x - body_pos 
			if distance_diference < 0:
				distance_diference *= -1
			if distance_diference < closest_vec_pos_x:
				closest_vec = i
				closest_vec_pos_x = distance_diference
		vecs_velocity[closest_vec] -= force_applied
		
		if body.has_method("_on_water_entered"):
			body._on_water_entered(water, HEIGHT, TENSION, DAMPING)
		
		if emit_particles:
			if audio_splash:
				var audioSplash = AudioStreamPlayer.new()
				audioSplash.stream = audio_splash
				audioSplash.volume_db = randomizator.randf_range(-50,-10)
				audioSplash.connect("finished", _on_audoSplashFinished.bind(audioSplash))
				add_child(audioSplash)
				audioSplash.play()
				
			var droplets = water_particles.instantiate()
			droplets.name = "particles"
			droplets.amount = (randomizator.randi() % 30) + 5
			droplets.lifetime = 3
			droplets.speed_scale = 3
			droplets.explosiveness = 1
			droplets.one_shot = true
			droplets.texture = droplet_texture
			droplets.color = WATER_COLOR
			droplets.add_to_group("water_droplets")
			
			var gradientRamp = Gradient.new()
			var corStart = WATER_COLOR
			var corEnd = WATER_COLOR
			corStart.a = particles_alpha
			corEnd.a = 0
			
			gradientRamp.add_point(0, corStart)
			gradientRamp.add_point(1, corEnd)
			
			droplets.color_ramp = gradientRamp
			droplets.z_index = body.z_index - 1
			droplets.global_position = Vector2(body.global_position.x, body.global_position.y)
			droplets.set_as_top_level(true)
			add_child(droplets)
			droplets.emitting = true

func body_not_emerged(body):
	if body is RigidBody2D or body is CharacterBody2D or body is StaticBody2D:
		if body.has_method("_on_water_exited"):
			body._on_water_exited()

func _draw():
	var vecs = PackedVector2Array([])
	var color = PackedColorArray([])
	if Engine.is_editor_hint():
		vecs = PackedVector2Array([Vector2(0, -HEIGHT), Vector2(WIDTH, -HEIGHT), Vector2(WIDTH, 0), Vector2(0, 0)])
		color = PackedColorArray([WATER_COLOR, WATER_COLOR, WATER_COLOR, WATER_COLOR])
	draw_polygon(vecs, color)

func _on_audoSplashFinished(body):
	if weakref(body).get_ref():
		body.queue_free()

