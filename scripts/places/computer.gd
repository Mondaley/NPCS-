extends Node

@onready var n_overlay = $overlay
@onready var n_rich_text = $AspectRatioContainer/VBoxContainer/HBoxContainer/ColorRect5/MarginContainer/RichTextLabel

#var stg_old_pc_cursor = load("res://gfx/ui/cursor.png")

var stg_subject := ""
var stg_name := ""
var stg_statuts := ""
var stg_decription := ""


#func  _ready():
	#Input.set_custom_mouse_cursor(stg_old_pc_cursor)
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	random_brightness()
	play_sounds()

func random_brightness():
	var value = randf_range(0.8, 0.85)
	n_overlay.self_modulate = Color(value, value, value, value)

func update_rich_text():
	n_rich_text.set_text( 
		"[font_size=40]Subject:[/font_size]\n" +
		"[font_size=25]" + stg_subject + "[/font_size]" + "\n"+
		"[font_size=40]________[/font_size]\n\n\n" +
		"[font_size=40]From:[/font_size]\n" +
		"[font_size=25]" + stg_name + "[/font_size]" + "\n"+
		"[font_size=40]________[/font_size]\n\n\n" +
		"[font_size=40]Status:[/font_size]\n" +
		"[font_size=25]" + stg_statuts + "[/font_size]" + "\n"+
		"[font_size=40]________[/font_size]\n\n\n" +
		"[font_size=40]Description:[/font_size]\n" +
		"[font_size=25]" + stg_decription + "[/font_size]" +
		"\n\n\n\n\n\n\n\n\n\n\n\n"
	)
	print(n_rich_text.text )

func play_sounds():
	if Input.is_action_just_pressed("mouse_select"):
		$sounds/mouse.stream = load("res://sfx/places/computer/click_press.wav")
		$sounds/mouse.play()
	if Input.is_action_just_released("mouse_select"):
		$sounds/mouse.stream = load("res://sfx/places/computer/click_release.wav")
		$sounds/mouse.play()


func _on_location_button_pressed():
	pass # Replace with function body.
