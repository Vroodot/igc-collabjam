extends RigidBody2D
class_name FlyingBook

var height :float=10.
var target_bookshelf :MagicBookshelf

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func start_flying():
	pass


func sort_into_bookshelf():
	pass


func find_bookshelf():
	var possible_bookshelves :Array[Node]
	for element in get_tree().get_nodes_in_group(&"Magic Bookshelf"):
		if element is MagicBookshelf:
			if element.can_store_book() and (element.bookshelf_shape.size.y >= height):
				possible_bookshelves.append(element)
	target_bookshelf = possible_bookshelves.pick_random()
