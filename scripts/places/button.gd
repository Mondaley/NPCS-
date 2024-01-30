extends Node

signal sg_button_pressed

@export_multiline var stg_subject := ""
@export_multiline var stg_name := ""
@export_multiline var stg_statuts := ""
@export_multiline var stg_decription := ""

# Called when the node enters the scene tree for the first time.
func _ready():
	self["text"] = stg_name + "\n" + stg_statuts
	connect("sg_button_pressed", Callable(owner, "update_rich_text"))
	connect("pressed", button_pressed)

func button_pressed():
	owner.stg_subject = stg_subject
	owner.stg_name = stg_name
	owner.stg_statuts = stg_statuts
	owner.stg_decription = stg_decription
	emit_signal("sg_button_pressed")
