extends Resource
class_name ingredient

signal take_ingredient

@export var name: String  = ""
@export var point: int = 0
@export var isPull: bool = false

##TODO
func taken_by_player() -> void:
	pass
