@tool
extends MeshInstance3D

@export var wheelMarkers: Array[Marker3D]


func _ready() -> void:
	pass

func _physics_process(delta: float) -> void:
	rotate_y(delta * 0.4)
	
	var a = DebugDraw3D.new_scoped_config().set_thickness(0.015)
	
	var castDistance = 10.0;
	
	var wheelPoints: Array[Vector3]
	var highestWheelIndex = 0
	var lowestWheelIndex = 0
	
	var wheelIndex = 0
	for wheelMarker in wheelMarkers:
		var wheelPosition = wheelMarker.global_position
		var wheelDown = -wheelMarker.global_transform.basis.y
		
		var query = PhysicsRayQueryParameters3D.create(wheelPosition,wheelPosition + wheelDown * castDistance)
		var collision = get_world_3d().direct_space_state.intersect_ray(query)
		if collision.is_empty():
			continue
			
		var hitPoint = collision["position"]
		DebugDraw3D.draw_line(query.from, hitPoint, Color.DIM_GRAY)
		DebugDraw3D.draw_sphere(hitPoint,0.025,Color.DIM_GRAY)
		wheelPoints.push_back(hitPoint)
		
		if hitPoint.y > wheelPoints[highestWheelIndex].y:
			highestWheelIndex = wheelIndex
			
		if hitPoint.y < wheelPoints[lowestWheelIndex].y:
			lowestWheelIndex = wheelIndex
			
			
		wheelIndex += 1
		
		
	if wheelPoints.is_empty() or wheelPoints.size() != 4:
		return
	
	var highestWheel: Vector3 = wheelPoints[highestWheelIndex]
	var oppositeWheel: Vector3 = wheelPoints[(highestWheelIndex + 2)%4]
	var closeWheel = wheelPoints[(highestWheelIndex + 1)%4]
	var farWheel = wheelPoints[(highestWheelIndex + 3)%4]
	
	if (highestWheel - closeWheel).length_squared() > (highestWheel - farWheel).length_squared():
		var oldcloseWheel = closeWheel
		closeWheel = farWheel
		farWheel = oldcloseWheel
	
	DebugDraw3D.draw_sphere(highestWheel,0.05,Color.LIME_GREEN)
	DebugDraw3D.draw_sphere(oppositeWheel,0.05,Color.ORANGE_RED)

	var closeDirection = (closeWheel - highestWheel)
	var farDirection = (farWheel - highestWheel)
	var connectedOppositeWheel = highestWheel + closeDirection + farDirection
	

	
	
	var diff = connectedOppositeWheel - oppositeWheel 
	
	
	if diff.y < 0: # If the connected opposite wheel is in the ground we lift the close and far wheel equaly
		closeWheel= closeWheel - diff * 0.5
		farWheel = farWheel - diff * 0.5
	else: # When the opposite wheel is not in the ground we can simply connect it
		oppositeWheel = connectedOppositeWheel
		
	DebugDraw3D.draw_line(highestWheel, closeWheel,Color.YELLOW)
	DebugDraw3D.draw_line(highestWheel, farWheel,Color.YELLOW)
	DebugDraw3D.draw_line(oppositeWheel, closeWheel,Color.YELLOW)
	DebugDraw3D.draw_line(oppositeWheel, farWheel,Color.YELLOW)
		
		
