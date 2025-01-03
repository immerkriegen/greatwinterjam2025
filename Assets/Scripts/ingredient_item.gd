extends Area3D

@export var ingredientType: ingredient 

func _process(delta: float):
	pass

func on_ingredient_entered():
	print_debug(ingredientType.name)
	print_debug(ingredientType.point)


func _on_body_entered(body: Node3D) -> void:
	print_debug(ingredientType.name)
	print_debug(ingredientType.point)
