@tool
extends MeshInstance3D

@export var wheelMarkers: Array[Marker3D]
@export var vehicle: Node3D
@export var snap: bool
@export var slerp: bool
@export var rotate: bool
@export var heightOffset: float

var smoothRotation: Quaternion
var smoothPosition: Vector3

func _ready() -> void:
	pass

func _physics_process(delta: float) -> void:
	
	if snap == false:
		vehicle.transform = Transform3D.IDENTITY
		return
		
	if rotate:
		rotate_y(delta * 0.5)
		
	var a = DebugDraw3D.new_scoped_config().set_thickness(0.015)
	var groundPoints = find_ground_points();
	
	if groundPoints.size() != 4:
		return
		
	for point in groundPoints:
		DebugDraw3D.draw_sphere(point,0.05,Color.DARK_SLATE_GRAY)
		
	var wheels: Array[Vector3]
	wheels.resize(4)
	# fr - 0
	# fl - 1
	# bl - 2
	# br - 3
	for wheel in groundPoints:
		if to_local(wheel).x < 0 and to_local(wheel).z > 0:
			wheels[0] = wheel
		elif to_local(wheel).x > 0 and to_local(wheel).z > 0:
			wheels[1] = wheel
		elif to_local(wheel).x > 0 and to_local(wheel).z < 0:
			wheels[2] = wheel
		elif to_local(wheel).x < 0 and to_local(wheel).z < 0:
			wheels[3] = wheel
	
	# Get highest wheel
	var heighestWheelIndex: int
	for i in wheels.size():
		if wheels[i].y > wheels[heighestWheelIndex].y:
			heighestWheelIndex = i
			
	# Get opposite to highest
	var oppositeWheelIndex: int = (heighestWheelIndex + 2) % 4
	var center = lerp(wheels[heighestWheelIndex],wheels[oppositeWheelIndex],0.5)
	
	var sideWheel1Index: int = (heighestWheelIndex + 1) % 4
	var sideWheel2Index: int = (heighestWheelIndex + 3) % 4
	var heighestSidewheelIndex: int = sideWheel1Index  if wheels[sideWheel1Index].y > wheels[sideWheel2Index].y else sideWheel2Index 
	var lowestSidewheelIndex: int = (heighestSidewheelIndex + 2) % 4
	
	
	var colorMode = Color.YELLOW
	
	# If we are still under center
	if wheels[heighestSidewheelIndex].y < center.y:
		wheels[heighestSidewheelIndex].y = center.y
		wheels[lowestSidewheelIndex].y = center.y
		colorMode = Color.BLUE
	else:	
		var dir1 = wheels[heighestWheelIndex] - wheels[heighestSidewheelIndex]
		var dir2= wheels[oppositeWheelIndex] - wheels[heighestSidewheelIndex]
		var connectedPoint = wheels[heighestSidewheelIndex] + dir1 + dir2
		
		var heightDiff = connectedPoint.y - wheels[lowestSidewheelIndex].y
		
		if heightDiff < 0:
			var balance = 0.5
			wheels[oppositeWheelIndex].y -= heightDiff * balance
			wheels[heighestWheelIndex].y -= heightDiff * (1 - balance)
			center = lerp(wheels[heighestWheelIndex],wheels[oppositeWheelIndex],0.5)
			colorMode = Color.RED
		else:
			wheels[lowestSidewheelIndex] = connectedPoint
			colorMode = Color.GREEN
			
			
		
	
	
	DebugDraw3D.draw_sphere(wheels[heighestWheelIndex],0.1,Color.GREEN)
	DebugDraw3D.draw_sphere(wheels[oppositeWheelIndex],0.1,Color.RED)
	DebugDraw3D.draw_line(wheels[heighestWheelIndex],wheels[oppositeWheelIndex],colorMode)
	
	DebugDraw3D.draw_sphere(wheels[heighestSidewheelIndex],0.1,Color.YELLOW)
	DebugDraw3D.draw_sphere(wheels[lowestSidewheelIndex],0.1,Color.YELLOW)
	DebugDraw3D.draw_line(wheels[heighestSidewheelIndex],wheels[lowestSidewheelIndex],colorMode)
	
	
	DebugDraw3D.draw_line(wheels[0],wheels[1],colorMode)
	DebugDraw3D.draw_line(wheels[1],wheels[2],colorMode)
	DebugDraw3D.draw_line(wheels[2],wheels[3],colorMode)
	DebugDraw3D.draw_line(wheels[3],wheels[0],colorMode)
	

	
	var forward: Vector3 = (wheels[0] - wheels[3]).normalized()
	var left: Vector3 = (wheels[2] - wheels[3]).normalized()
	var up: Vector3 = forward.cross(left)
		
	DebugDraw3D.draw_sphere(center,0.1,Color.DEEP_SKY_BLUE)
	DebugDraw3D.draw_arrow(center, center + forward * 1.1,Color.SKY_BLUE,0.05,true)
	DebugDraw3D.draw_arrow(center, center + left* 1.1,Color.INDIAN_RED,0.05,true)
	DebugDraw3D.draw_arrow(center, center + up* 1.1,Color.PALE_GREEN,0.05,true)
	
		
	var interpSpeed = delta * 20
	
	var correctLeft = up.cross(forward)
	
	var targetBasis = Basis()
	targetBasis.x = correctLeft
	targetBasis.y = up
	targetBasis.z = forward
	targetBasis = targetBasis.orthonormalized()
	
	DebugDraw3D.draw_arrow(center, center + targetBasis.x,Color.RED,0.1,true)
	DebugDraw3D.draw_arrow(center, center + targetBasis.y,Color.GREEN,0.1,true)
	DebugDraw3D.draw_arrow(center, center + targetBasis.z,Color.BLUE,0.1,true)
	
	
	if slerp:
		smoothRotation = smoothRotation.slerp(targetBasis.get_rotation_quaternion(),interpSpeed)
		smoothPosition = smoothPosition.lerp(center,interpSpeed)
	else:
		smoothRotation = targetBasis.get_rotation_quaternion()
		smoothPosition = center
		
	vehicle.transform = Transform3D.IDENTITY
	vehicle.global_rotation = smoothRotation.get_euler()
	vehicle.global_position = smoothPosition
	
	
	
func find_ground_points() -> Array[Vector3]:
	var castDistance = 10.0;
	var groundPoints: Array[Vector3]
	
	for wheelMarker in wheelMarkers:
		var query = PhysicsRayQueryParameters3D.create(wheelMarker.global_position,wheelMarker.global_position - wheelMarker.global_transform.basis.y * castDistance)
		var collision = get_world_3d().direct_space_state.intersect_ray(query)
		
		if collision.is_empty():
			continue
			
		var hitPoint: Vector3 = collision["position"]
		groundPoints.push_back(hitPoint)

	return groundPoints
