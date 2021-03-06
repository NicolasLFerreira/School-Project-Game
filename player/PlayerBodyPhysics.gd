extends KinematicBody2D

# Physics constants

const gravity = 5;
var vector = Vector2(0, 1);
var dash_vector = Vector2(0, 1);

# Movement variables

const movement_speed_base = 45;
var movement_speed = movement_speed_base;
var speed_jump = -300;
var sneak_factor = 3;

# Stamina variables

const stamina_cap = 100;
var stamina_regen = 5;
var stamina_cost = 5;
var stamina = 100;
var tired = false;

# Power

const power_cap = 100;
var power_regen = 10;
var power = 100;

const base_factor = 75;
var dash_factor = 0;
const projectile = preload("res://player/projectile/ProjectileBody.tscn");

# Death and combat

var mortal = true;
var die = false;

# Dev & Jokes

var god_mode = false;
var god_speed = 250;

func _process(delta):
	
	# Stats fix
	
	if (stamina > stamina_cap):
		stamina = stamina_cap;
	if (power > power_cap):
		power = power_cap;
	
	# Cheat and god mode
	
	if (global_script.cheatmode):
		
		# Teleport
		
		if (Input.is_action_just_pressed("teleport")):
			self.position.x += movement_speed * dash_factor / 2;
		
		# Full stats
		
		if (Input.is_action_just_pressed("full_stats")):
			stamina = stamina_cap;
			power = power_cap;
			tired = false;
		
		# Godmode
		
		if (Input.is_action_just_pressed("G")):
			god_mode = !god_mode;
			mortal = !mortal;
		
		if (god_mode):
			
			# Up down fly
			
			if (key("up")):
				vector.y -= god_speed;
			
			if (key("down")):
				vector.y += god_speed;
			
			# Unlimited stuff
			
			power = power_cap;
			stamina = stamina_cap;

func _physics_process(_delta):
	
	# Physics dependent functions
	
	movement();
	skill();
	stamina();
	shoot();
	die();
	
	# Movement and ground definition
	
	dash_vector = move_and_slide(dash_vector, Vector2());
	vector = move_and_slide(vector, Vector2(0, -1));
	
	# 'is_on_floor' conditions
	
	if (!is_on_floor()):
		
		# Gravity
		
		if (!god_mode):
			vector.y += gravity;
			vector.y += gravity;
		else:
			vector.y = 0;
		
		# Inertia
		
		vector.x = lerp(vector.x, 0, 0.03);
	else:
		vector.x = lerp(vector.x, 0, 0.3);
	
	dash_vector.x = lerp(dash_vector.x, 0, 0.3);
	
	# Walking animation
	
	if (!key("walk_left") and !key("walk_right")):
		$PlayerSprite.play("idle");
	else:
		$PlayerSprite.play("moving");
	

# Shortner

func key(key):
	
	if (Input.is_action_pressed(key)):
		return true;
	else: 
		return false;

# Walking, running and jumping function

func movement():
	
	# Walking right
	
	if (key("walk_right")):
		vector.x = max(vector.x-movement_speed, movement_speed * 4);
		$PlayerSprite.flip_h = false;
		dash_factor = base_factor;
	
	# Walking left
	
	if (key("walk_left")):
		vector.x = min(vector.x+movement_speed, -movement_speed * 4);
		$PlayerSprite.flip_h = true;
		dash_factor = -base_factor;
	
	# Jumping
	
	if (key("jump") and is_on_floor()):
		vector.y = speed_jump;

# Stamina

func stamina():
	
	# Cooldown for when stamina reaches 0
	
	if (stamina <= 0):
		tired = true;
	
	if (stamina == stamina_cap):
		tired = false;
	
	# Fix stamina
	
	if (stamina > stamina_cap):
		stamina = stamina_cap;
		$StaminaRegenTimer.stop();
	
	# Running
	
	if (!tired and key("sprint") and (key("walk_right") or key("walk_left"))):
		movement_speed = movement_speed_base * 2;
		if ($StaminaCostTimer.time_left == 0):
			$StaminaCostTimer.start();
			$StaminaRegenTimer.stop();
			$PlayerSprite.get_sprite_frames().set_animation_speed("moving", 9.0);
	# Sneaking
	else:
		if (key("sneak")):
			movement_speed = movement_speed_base / sneak_factor;
			$PlayerSprite.get_sprite_frames().set_animation_speed("moving", 3.0);
		else:
			movement_speed = movement_speed_base;
			$PlayerSprite.get_sprite_frames().set_animation_speed("moving", 6.0);
		$StaminaCostTimer.stop();
	if (stamina < stamina_cap and $StaminaRegenTimer.time_left == 0 and !key("sprint")):
		$StaminaRegenTimer.start();

# Function for every skill that the player has + shooting system

func skill():
	
	
	
	if ($SkillTimer.time_left == 0):
		
		# Dash
		
		if (Input.is_action_just_pressed("dash") and power >= 30):
			dash_vector.x = movement_speed_base * dash_factor;
			power -= 30;
			$SkillTimer.start();
		
		# Air Jump
		
		if (Input.is_action_just_pressed("air_jump") and power >= 40 and !is_on_floor()):
			vector.y = speed_jump;
			power -= 40;
			instance_projectile(false);
			$SkillTimer.start();
		
		# Dodge
		
		if (Input.is_action_just_pressed("dodge") and power >= 60):
			$DodgeTimer.start();
			if ($DodgeTimer.time_left != 0):
				mortal = false;
				$PlayerSprite.flip_v = true;
			power -= 60
			$SkillTimer.start();
		
		# Spray
		
		if (key("spray")):
			pass
	
	# Regen
	
	if (power < power_cap and $PowerRegenTimer.is_stopped()):
		$PowerRegenTimer.start();
	

# Shooting

func shoot():
	
	if (Input.is_action_just_pressed("shoot") and $ReloadProjectileTimer.get_time_left() == 0 and power >= 10):
		power -= 10;
		$ReloadProjectileTimer.start();
		
		instance_projectile(true);

func instance_projectile(rotate):
	
	var projectile_instance = projectile.instance();
	
	add_child(projectile_instance);
	
	projectile_instance.global_position = global_position;
	projectile_instance.direction = -1 if $PlayerSprite.flip_h else 1;
	projectile_instance.flip = true if $PlayerSprite.flip_h else false;
	projectile_instance.horizontal = rotate;

# Death

func _on_deadlyobject_enter(body):
	if (body.get_name() == "DeadlyObjectsTileSet"):
		die = true;

func _on_deadlyobject_exit(body):
	if (body.get_name() == "DeadlyObjectsTileSet"):
		die = false;

func _on_enemy_enter(area):
	if (area.get_name() == "HitArea"):
		die = true;

func _on_enemy_exit(area):
	if (area.get_name() == "HitArea"):
		die = false;

func die():
	if (die and mortal):
		global_script.times_death += 1;
		get_tree().reload_current_scene();

# Timer functions

func _stamina_cost_timer():
	stamina -= stamina_cost;

func _stamina_regen_timer():
	stamina += stamina_regen;

func _power_regen_timer():
	power += power_regen;

func _dodge_end_timer():
	mortal = true;
	$PlayerSprite.flip_v = false;
