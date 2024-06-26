extends Node2D

@onready var line_2d_2 = $Line2D2
@onready var line_2d = $Line2D
@onready var marker_2d = $Marker2D
@onready var slingshot = $Slingshot
@onready var area_2d = $Area2D
@onready var camera_2d = $Camera2D

#最大拉伸位置
@export var max_stretch_distance: float = 150

#抛物线纹理与最大数量
var point_texture = preload ("res://assets/textures/point.png")
var points = []
@export var max_points: int = 20

#初始速度
@export var inital_velocity_factor = 10

#初始位置，拖动位置，拖动状态
var start_position: Vector2
var drag_position := Vector2.ZERO
var can_drag: bool = false:
	set(value):
		can_drag = value
		line_2d.visible = can_drag
		line_2d_2.visible = can_drag
		slingshot.visible = can_drag

#重力
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")

#子弹实例
var bullet_scene: PackedScene = preload ("res://src/entities/bullet.tscn")
var bullet = null

func _ready():
	start_position = marker_2d.position
	area_2d.input_event.connect(_on_area_2d_input_event)
	setup_init_points()
	bullet = bullet_scene.instantiate()
	marker_2d.add_child(bullet)
	bullet.position = marker_2d.position
	bullet.gravity_scale = 0

func _process(_delta):
	update_camera_position()

	if can_drag:
		update_sling_band()
		update_trajectory()

func _unhandled_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if can_drag:
			launch()
			can_drag = false
			drag_position = start_position
			for p in points:
				p.visible = false

#初始化抛物线的方法
func setup_init_points():
	for i in range(max_points):
		var point = Sprite2D.new()
		point.texture = point_texture
		points.append(point)
		add_child(point)
		point.visible = false

func update_sling_band():
	var local_mouse_position = get_local_mouse_position()
	 #当前鼠标位置减去起始位置
	var stretch_vector = local_mouse_position - start_position
	if stretch_vector.x > - 50:
		stretch_vector.x = -50
	#限制拉伸位置
	stretch_vector = _clamp_vector_to_length(stretch_vector, max_stretch_distance)
	drag_position = start_position + stretch_vector

	line_2d.points[1] = drag_position + Vector2( - 25, 15)
	line_2d_2.points[1] = drag_position + Vector2( - 25, 15)
	slingshot.position = drag_position + Vector2( - 25, 15)
	bullet.global_position = to_global(drag_position)

#更新抛物线
func update_trajectory():
	var initail_velocity = _get_launch_velocity()
	var time_step = 0.1
	var total_time = 2.0
	var current_time = 0.0
	var index = 0
	while current_time <= total_time and index < max_points:
		points[index].global_position = to_global(
			Vector2(
				start_position.x + initail_velocity.x * current_time,
				start_position.y + initail_velocity.y * current_time + gravity * current_time * current_time * 0.5
			)
		)
		points[index].visible = true
		current_time += time_step
		index += 1
	for i in range(index, max_points):
		points[i].visible = false

#摄像机
func update_camera_position():
	if not bullet: return
	if bullet.linear_velocity.length() > 10:
		camera_2d.global_position = bullet.global_position
#发射子弹
func launch():
	bullet.gravity_scale = 1
	bullet.linear_velocity = _get_launch_velocity()

#获取初始速度
func _get_launch_velocity():
	var stretch_velocity = start_position - drag_position
	return stretch_velocity * inital_velocity_factor

func _clamp_vector_to_length(v: Vector2, max_length: float):
	return v.normalized() * max_length if max_length < v.length() else v

func _on_area_2d_input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.is_pressed():
			can_drag = true
		else:
			can_drag = false
			drag_position = start_position
