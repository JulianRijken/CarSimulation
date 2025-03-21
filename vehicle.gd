@tool
extends MeshInstance3D

@export var wheelMarkers: Array[Marker3D]


func _ready() -> void:
	pass

func _physics_process(delta: float) -> void:
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
		DebugDraw3D.draw_line(query.from, hitPoint, Color(1, 1, 0))
		#DebugDraw3D.draw_sphere(hitPoint,0.05)
		wheelPoints.push_back(hitPoint)
		
		if hitPoint.y > wheelPoints[highestWheelIndex].y:
			highestWheelIndex = wheelIndex
			
		if hitPoint.y < wheelPoints[lowestWheelIndex].y:
			lowestWheelIndex = wheelIndex
			
			
		wheelIndex += 1
		
	if wheelPoints.is_empty() or wheelPoints.size() != 4:
		return
		
	#wheelPoints.sort_custom(func(a, b): return a.y > b.y)
	
	var oppositeWheel = wheelPoints[(lowestWheelIndex + 2)%4]
	var sideWheel1 = wheelPoints[(lowestWheelIndex + 1)%4]
	var sideWheel2 = wheelPoints[(lowestWheelIndex + 3)%4]
	
	var dir1 = (sideWheel1 - oppositeWheel)
	var dir2 = (sideWheel2 - oppositeWheel)
	var dir1n = (sideWheel1 - oppositeWheel).normalized()
	var dir2n = (sideWheel2 - oppositeWheel).normalized()
	
	var foundWheel = oppositeWheel + dir1 + dir2;
	
	var up = dir1n.cross(dir2n)
	DebugDraw3D.draw_arrow(global_position,global_position + up,Color.RED,0.1)
	
	DebugDraw3D.draw_line(oppositeWheel,sideWheel1,Color.MEDIUM_SLATE_BLUE)
	DebugDraw3D.draw_line(oppositeWheel,sideWheel2,Color.MEDIUM_SLATE_BLUE)
	DebugDraw3D.draw_line(sideWheel1,foundWheel,Color.CORAL)
	DebugDraw3D.draw_line(sideWheel2,foundWheel,Color.CORAL)
	
	
	DebugDraw3D.draw_sphere(oppositeWheel,0.05,Color.GREEN)
	DebugDraw3D.draw_sphere(sideWheel1,0.05,Color.REBECCA_PURPLE)
	DebugDraw3D.draw_sphere(sideWheel2,0.05,Color.BLUE_VIOLET)
	DebugDraw3D.draw_sphere(foundWheel,0.05,Color.RED)
	
	
			
	#var highestWheel = wheelPoints[highestWheelIndex]
	#var sideWheel1 = wheelPoints[(highestWheelIndex + 1)%4]
	#var sideWheel2 = wheelPoints[(highestWheelIndex + 3)%4]
	#
	#var averageHeight = highestWheel.y - oppositeWheel.y
		#
	#DebugDraw3D.draw_sphere(highestWheel,0.05,Color.GREEN)
	#DebugDraw3D.draw_sphere(oppositeWheel,0.05,Color.RED)
	#DebugDraw3D.draw_sphere(sideWheel1,0.05,Color.DEEP_SKY_BLUE)
	#DebugDraw3D.draw_sphere(sideWheel2,0.05,Color.MIDNIGHT_BLUE)
	#
	#DebugDraw3D.draw_line(highestWheel,oppositeWheel,Color.DARK_RED)
	
	
	
	
	#var sideWheel1
	#var sideWHeel2	
	
