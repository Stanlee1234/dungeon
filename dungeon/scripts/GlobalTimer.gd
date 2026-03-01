extends Node

var time_passed = 0.0
var timer_active = false

func _process(delta: float) -> void:
	if timer_active:
		time_passed += delta

func reset_timer():
	time_passed = 0.0
	timer_active = true

func format_time() -> String:
	var mins = int(time_passed / 60)
	var secs = int(time_passed) % 60
	var msecs = int((time_passed - int(time_passed)) * 1000)
	return "%02d:%02d.%03d" % [mins, secs, msecs]
