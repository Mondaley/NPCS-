extends ScrollContainer

@export var Head_Over_Button: Button


func _on_scroll_ended():
	Head_Over_Button.visible = true


func _on_scroll_started():
	Head_Over_Button.visible = false
