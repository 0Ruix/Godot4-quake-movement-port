extends CharacterBody3D

# 23.04.2023 // dd/mm/yy
#Original code by TheHyper-Dev --> github.com/TheHyper-Dev
#Ported to GDscript 2.0 by 0Ruix --> github.com/0Ruix
#Also thanks to www.youtube.com/@MattsRamblings and to other that i've forgotten about sorry.
#There are still problems. If you have a  solution please let me know...
#I'll clean this code when i finally get it working normally

@onready var body = self
@onready var head = $Head

var _rot:Vector2

@export_range(0.1,1.0) var sens = 0.1

#PLAYER VARIABLES
@export var friction = 6.0
@export var moveSpeed = 7.0
@export var groundAccel = 14.0
@export var groundDeAccel = 10.0
@export var airAccel = 2.0
@export var jumpSpeed = 4.0
@export var debug = true


var wishDir = Vector3.ZERO
var playerVelocity = Vector3.ZERO

var wishJump = false
var autoJump = true

#maybe add a way to remove wish jump?

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

func _unhandled_input(event):
	wish_jump_logic(event)
	setDir()

func _input(event):
	if event is InputEventMouseMotion:
		_rot += -event.relative * sens
		_rot.y = clamp(_rot.y,-85,85)
		
		body.rotation_degrees = Vector3(0,_rot.x,0)
		head.rotation_degrees = Vector3(_rot.y,0,0)

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

var cam_accel:float = 40

func _process(delta):
#	Breaks occasionaly
#	if Engine.get_frames_per_second() > Engine.physics_ticks_per_second:
#		head.position = lerpf(head.position,0,cam_accel * delta)
#	else:
#		head.position = Vector3.ZERO
	pass

func setDir():
	#Probably need to find a better way of calculating wishDir
	var moveKeyInput = Vector2.ZERO
	moveKeyInput = Input.get_vector("moveleft","moveright","back","forward")
	wishDir = Vector3(moveKeyInput.x,0,-moveKeyInput.y).rotated(Vector3.UP,body.rotation.y).normalized()

func _physics_process(delta):
	#Get Input Vec
	queue_jump()
	
	if is_on_floor():
		ground_move()
	else:
		air_move()
	
	velocity = playerVelocity #Override the internal velocity
	move_and_slide()
	#DEBUG
	if debug:
		get_node("Control/speed").text = "SPEED\n" + str(velocity.length())
		
		var per = velocity.length() / moveSpeed*100 #Percentage of the speed against the "limit"
		if per > velocity.length():
			get_node("Control/speedPer").label_settings.set_font_color(Color(0,1,0,1))
		else:
			get_node("Control/speedPer").label_settings.set_font_color(Color(1,1,1,1))
			
		get_node("Control/speedPer").text = "%" + str(snapped(velocity.length() / moveSpeed*100,0.01))
		get_node("Control/wJump").text = "wish jump : " + str(wishJump)
		get_node("Control/fps").text = "FPS: " + str(Engine.get_frames_per_second())
		get_node("Control/dirs").text = "Wish: " + str(wishDir) + "\nVelocity: " + str(velocity)
		get_node("Control/grounded").text = "Grounded: " + str(is_on_floor())
		
		#Blue is wishdir and green is velocity
		DebugDraw.draw_line(position, position + wishDir,Color.BLUE)
		DebugDraw.draw_line(position, position + velocity,Color.GREEN)

func apply_friction(enabled:bool):
	if !enabled:
		return
	
	var pVecCopy = playerVelocity
	var drop = 0 
	pVecCopy.y = 0
	var lastSpeed = pVecCopy.length()
	var control:float
	var newSpeed:float
	
	if (is_on_floor()):
		if lastSpeed < groundDeAccel:
			control = groundAccel
		else:
			control = lastSpeed
		
		drop = control * friction * get_physics_process_delta_time()
	
	newSpeed = lastSpeed - drop
	
	if newSpeed < 0:
		newSpeed = 0 
	if lastSpeed > 0:
		newSpeed /= lastSpeed
	
	playerVelocity.x *= newSpeed
	playerVelocity.z *= newSpeed

func wish_jump_logic(event:InputEvent):
	if event.is_action_pressed("jump") and !wishJump:
		wishJump = true #
	if event.is_action_released("jump"):
		wishJump = false

func queue_jump():
	if autoJump:
		wishJump = Input.is_action_pressed("jump")

func ground_move():
	apply_friction(!wishJump) #change to !wishjump
	accelerate(wishDir,wishSpeed(),groundAccel)
	
	if wishJump:
		wishJump = false
		playerVelocity.y = jumpSpeed #states might be usefull

func air_move():
	accelerate(wishDir,wishSpeed(),airAccel)
	playerVelocity.y += -gravity * get_physics_process_delta_time() 

func wishSpeed():
	return wishDir.length_squared() * moveSpeed

func accelerate(wd,wishSpeed,accel):
	var current_speed = playerVelocity.dot(wd)
	var add_speed = wishSpeed - current_speed
	var accelSpeed:float = 0.0
	
	if add_speed <= 0:
		return
	
	accelSpeed = accel * get_physics_process_delta_time() * wishSpeed()
	
	if accelSpeed > accel:
		accelSpeed = add_speed
	
	playerVelocity.x += accelSpeed * wishDir.x
	playerVelocity.z += accelSpeed * wishDir.z
