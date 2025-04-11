@tool
extends Area2D
class_name MagicBookshelf

@export var book_width :float=10.0 ##Maximum width per book in pixels - used to determine amount of book slots
@export_group("Book Leaving Checks")
@export var book_interval :float= 5.0 ##Seconds between each check for if a book can leave
@export_range(0.0,1.0,0.1) var book_chance :float= 0.5 ##Chance that a book will leave on an otherwise successful check
@export var bookshelf_shape :RectangleShape2D

var max_book_slots :int= 0
var book_slots :Array[FlyingBook]
var current_book_count :int=0

@onready var timer :Timer= $BookLeavingTimer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if !Engine.is_editor_hint():
		timer.wait_time = book_interval
		max_book_slots = bookshelf_shape.size.x/book_width
		for i in range(max_book_slots):
			book_slots.append(null)
	if (get_parent()==get_viewport()):
		return
	if !bookshelf_shape:
		var new_collision_shape = CollisionShape2D.new()
		add_child(new_collision_shape)
		#new_collision_shape.owner = self
		if get_parent().owner:
			new_collision_shape.owner = get_parent().owner
		else:
			new_collision_shape.owner = get_parent()
		print("Creating shape for bookshelf: ", new_collision_shape)
		new_collision_shape.shape = RectangleShape2D.new()
		bookshelf_shape = new_collision_shape.shape


func _on_book_leaving_timer_timeout() -> void:
	if randf() <= book_chance:
		for book:FlyingBook in book_slots:
			if book:
				print("one book is leaving")
				return

func can_store_book()->bool:
	return current_book_count < max_book_slots
