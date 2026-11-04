extends Label

@export var duration: float = 500.0

var time_left: float
var is_running: bool = false

func _ready():
	reset_timer()

func _process(delta):
	if not is_running:
		return

	time_left -= delta

	if time_left <= 0:
		time_left = 0
		is_running = false
		game_over()

	update_timer_display()


func update_timer_display():
	var total_centiseconds = int(ceil(time_left * 100.0))

	var minutes = total_centiseconds / 6000
	var seconds = (total_centiseconds / 100) % 60
	var centiseconds = total_centiseconds % 100

	text = "%02d:%02d:%02d" % [
		minutes,
		seconds,
		centiseconds
	]


func start_timer():
	is_running = true


func stop_timer():
	is_running = false


func reset_timer():
	time_left = duration
	is_running = false
	update_timer_display()

func game_over():
	get_parent().get_parent().game_over()
