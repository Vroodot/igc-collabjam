class_name NodeHandler
extends RefCounted #node_handler.gd


#region Node Removal / Deletion
static func is_node_valid(node: Node) -> bool:
	return node != null and is_instance_valid(node) and not node.is_queued_for_deletion()


static func remove(node: Node) -> void:
	if is_node_valid(node):
		if node.is_inside_tree():
			node.queue_free()
		else:
			node.call_deferred("free")


static func remove_and_queue_free_children(node: Node, except: Array = []) -> void:
	if node.get_child_count() == 0:
		return

	var childrens = node.get_children().filter(func(child): return not child.get_class() in except)
	childrens.reverse()

	for child in childrens.filter(func(_node: Node): return is_node_valid(_node)):
		node.remove_child(child)
		remove(child)


static func queue_free_children(node: Node, except: Array = []) -> void:
	if node.get_child_count() == 0:
		return

	var childrens = node.get_children().filter(func(child): return not child.get_class() in except)
	childrens.reverse()

	for child in childrens.filter(func(_node: Node): return is_node_valid(_node)):
		remove(child)

	except.clear()



static func free_children(node: Node, except: Array = []) -> void:
	if node.get_child_count() == 0:
		return

	var childrens = node.get_children().filter(func(child): return not child.get_class() in except)
	childrens.reverse()

	for child in childrens.filter(func(_node: Node): return is_node_valid(_node)):
		child.free()

	except.clear()
#endregion

#region Positional functions relating to Node2D
static func global_direction_to_v2(a: Node2D, b: Node2D) -> Vector2:
	return a.global_position.direction_to(b.global_position)


static func local_direction_to_v2(a: Node2D, b: Node2D) -> Vector2:
	return a.position.direction_to(b.position)


static func global_distance_to_v2(a: Node2D, b: Node2D) -> float:
	return a.global_position.distance_to(b.global_position)


static func local_distance_to_v2(a: Node2D, b: Node2D) -> float:
	return a.position.distance_to(b.position)

# Use on _process or _physic_process
static func rotate_toward_v2(from: Node2D, to: Node2D, lerp_weight: float = 0.5) -> void:
	from.rotation = lerp_angle(from.rotation, global_direction_to_v2(to, from).angle(), clamp(lerp_weight, 0.0, 1.0))




static func get_nearest_node_by_distance(from: Vector2, nodes: Array = [], min_distance: float = 0.0, max_range: float = 9999) -> Dictionary:
	var result := {"target": null, "distance": null}

	for node in nodes.filter(func(node): return node is Node2D or node is Node3D): ## Only allows node that can use global_position in the world
		var distance_to_target: float = node.global_position.distance_to(from)

		if Math.decimal_value_is_between(distance_to_target, min_distance, max_range) and (result.target == null or (distance_to_target < result.distance)):
			result.target = node
			result.distance = distance_to_target


	return result


static func get_nearest_nodes_sorted_by_distance(from: Vector2, nodes: Array = [], min_distance: float = 0.0, max_range: float = 9999) -> Array:
	var nodes_copy = nodes.duplicate()\
		.filter(func(node): return (node is Node2D or node is Node3D) and Math.decimal_value_is_between(node.global_position.distance_to(from), min_distance, max_range))

	nodes_copy.sort_custom(func(a, b): return a.global_position.distance_to(from) < b.global_position.distance_to(from))

	return nodes_copy


static func get_farthest_node_by_distance(from: Vector2, nodes: Array = [], min_distance: float = 0.0, max_range: float = 9999) -> Dictionary:
	var farthest := {"target": null, "distance": 0.0}

	for node in nodes.filter(func(node): return node is Node2D or node is Node3D): ## Only allows node that can use global_position in the world
		var distance_to_target: float = node.global_position.distance_to(from)

		if Math.decimal_value_is_between(distance_to_target, min_distance, max_range) and (farthest.target == null or (distance_to_target > farthest.distance)):
			farthest.target = node
			farthest.distance = distance_to_target


	return farthest
#endregion


static func get_scene_owner(check_from_node:Node)->Node:
	if check_from_node.owner:
		return get_scene_owner(check_from_node.owner)
	else:
		return check_from_node
