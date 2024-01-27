extends CharacterBody2D

const MASS = 5.0
const ARRIVE_DISTANCE = 10.0
const death_delay = 5.0
const enemy_move_distance = 6
const Attack = preload("res://scripts/attack.gd")
const Utils = preload("res://scripts/utils.gd")

signal exhaust

@export var speed: float = 200.0

var _state = Utils.State.IDLE
var _velocity = Vector2()

@onready var _tile_map = $"../TileMap"
@onready var player = $"../Character"
@onready var baddie_sprite = $baddiesprite
@onready var baddie_orig_position = position

var _path = PackedVector2Array()
var _next_point = Vector2()
var hit_points : int
var x_distance : int
var y_distance : int


# Called when the node enters the scene tree for the first time.
func _ready():
	hit_points = 10
	_tile_map.enemy_turn.connect(_take_turn)
	baddie_sprite.animation_finished.connect(_return_to_idle)
	_change_state(Utils.State.IDLE)

func _process(_delta):
	if hit_points <= 0:
		die()
	if _state != Utils.State.FOLLOW:
		return
	var arrived_to_next_point = _move_to(_next_point)
	if arrived_to_next_point:
		_path.remove_at(0)
		if _path.is_empty():
			if player_adjacent():
				attack()
			else:
				_change_state(Utils.State.EXHAUSTED)
			return
		_next_point = _path[0]

func _move_to(local_position):
	var desired_velocity = (local_position - position).normalized() * speed
	var steering = desired_velocity - _velocity
	_velocity += steering / MASS
	
	position += _velocity * get_process_delta_time()
	#rotation = _velocity.angle()
	if Vector2.UP.angle() < _velocity.angle() && _velocity.angle() < Vector2.DOWN.angle():
		baddie_sprite.flip_h = false
	else:
		baddie_sprite.flip_h = true
	
	return position.distance_to(local_position) < ARRIVE_DISTANCE
	
func _change_state(new_state):
	if new_state == Utils.State.IDLE:
		_tile_map.clear_path()
		baddie_sprite.play("baddie_idle")
	elif new_state == Utils.State.EXHAUSTED:
		_tile_map.clear_path()
		baddie_sprite.play("baddie_idle")
		emit_signal("exhaust")
		print("ENEMY_EXHAUSTED")
	elif new_state == Utils.State.FOLLOW:
		_path = _tile_map.find_path(position, player.position, enemy_move_distance, true)
		if _path[_path.size() - 1] == _tile_map.get_tile_center(player.position):
			_path.resize(_path.size() - 1)
		baddie_sprite.play("baddie_move")
		if _path.size() < 2:
			_change_state(Utils.State.IDLE)
			return
		# The index 0 is the starting cell.
		# We don't want the character to move back to it in this example.
		_next_point = _path[1]
	_state = new_state

func _take_turn():
	
	if player_adjacent():
		attack()
	elif _tile_map.is_point_walkable(player.position) && _state != Utils.State.DYING:
		_change_state(Utils.State.FOLLOW)
	else:
		_change_state(Utils.State.EXHAUSTED)

func _return_to_idle():
	baddie_sprite.play("baddie_idle")

func on_hit(atk):
	print("DIRECT HIT")
	hit_points = hit_points - atk.damage
	
	
func die():
	_change_state(Utils.State.DYING)
	baddie_sprite.play("baddie_die")
	#await get_tree().create_timer(death_delay).timeout
	await baddie_sprite.animation_finished
	position = baddie_orig_position
	hit_points = 10
	baddie_sprite.play("baddie_idle")
	
func attack():
	_change_state(Utils.State.ATTACKING)
	baddie_sprite.play("baddie_attack")
	player.on_hit(Attack.new(7, player.position))
	await baddie_sprite.animation_finished
	baddie_sprite.play("baddie_idle")
	_change_state(Utils.State.EXHAUSTED)
	
func player_adjacent():
	x_distance = abs(_tile_map.local_to_map(position).x - _tile_map.local_to_map(player.position).x)
	y_distance = abs(_tile_map.local_to_map(position).y - _tile_map.local_to_map(player.position).y)
	if x_distance + y_distance <= 1:
		return true
	#print("I AM CLOSE! " + var_to_str(abs(_tile_map.local_to_map(position).x - _tile_map.local_to_map(player.position).x)))
	#_path = _tile_map.find_path(position, player.position, enemy_move_distance, true)

	
