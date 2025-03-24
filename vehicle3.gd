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

# This code does not simulate physics! 
# It MINIMIZES the distance from the wheels to the ground
# it prioritizes lifting 2 wheels if this means they can both be closer, instead of 1
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
		
	# Get wheels and assighn a side
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
	
	# Get lowest and heighest side wheels
	var sideWheel1Index: int = (heighestWheelIndex + 1) % 4
	var sideWheel2Index: int = (heighestWheelIndex + 3) % 4
	var heighestSideWheelIndex: int = sideWheel1Index  if wheels[sideWheel1Index].y > wheels[sideWheel2Index].y else sideWheel2Index 
	var lowestSideWheelIndex: int = (heighestSideWheelIndex + 2) % 4
	
	
	var colorMode

	# Get conect point
	var dir1 = wheels[heighestWheelIndex] - wheels[heighestSideWheelIndex]
	var dir2= wheels[oppositeWheelIndex] - wheels[heighestSideWheelIndex]
	var connectedPoint = wheels[heighestSideWheelIndex] + dir1 + dir2
	
	
	# Check lowest side to connect point 
	var lowestSideToConnectPoint = connectedPoint - wheels[lowestSideWheelIndex]
	if lowestSideToConnectPoint.y < 0:
		wheels[oppositeWheelIndex] -= lowestSideToConnectPoint * 0.5
		wheels[heighestWheelIndex] -= lowestSideToConnectPoint * 0.5
		colorMode = Color.BLACK
	else:
		wheels[lowestSideWheelIndex] += lowestSideToConnectPoint * 0.5
		wheels[heighestSideWheelIndex] += lowestSideToConnectPoint * 0.5
		colorMode = Color.WHITE


	# This wil not be orthonormal
	var forward: Vector3 = (wheels[0] - wheels[3]).normalized()
	var left: Vector3 = (wheels[2] - wheels[3]).normalized()
	var up: Vector3 = forward.cross(left)
	
	# We recalculate the left to make this orthonormal
	# We pick the left as it is prefered to keep the vehicle straight
	left = up.cross(forward) 
		

	var interpSpeed = delta * 20
	
	# 3x3 matrix with xyz, this is the target basis
	var targetBasis = Basis()
	targetBasis.x = left
	targetBasis.y = up
	targetBasis.z = forward
	targetBasis = targetBasis.orthonormalized()

	# Get rotation from basis
	var targetRotation = targetBasis.get_rotation_quaternion()
	
	# Get the box center
	var center = lerp(wheels[heighestWheelIndex],wheels[oppositeWheelIndex],0.5)
	
	if slerp:
		smoothRotation = smoothRotation.slerp(targetRotation,interpSpeed)
		smoothPosition = smoothPosition.lerp(center,interpSpeed)
	else:
		smoothRotation = targetRotation
		smoothPosition = center
		
	# Apply to vehicle transform
	vehicle.transform = Transform3D.IDENTITY
	vehicle.global_rotation = smoothRotation.get_euler()
	vehicle.global_position = smoothPosition + up * heightOffset
	
	
	
	
	
	# Draw heighest and lowest
	DebugDraw3D.draw_sphere(wheels[heighestWheelIndex],0.1,Color.GREEN)
	DebugDraw3D.draw_sphere(wheels[oppositeWheelIndex],0.1,Color.RED)
	DebugDraw3D.draw_line(wheels[heighestWheelIndex],wheels[oppositeWheelIndex],colorMode)
	
	# Draw sides
	DebugDraw3D.draw_sphere(wheels[heighestSideWheelIndex],0.1,Color.YELLOW)
	DebugDraw3D.draw_sphere(wheels[lowestSideWheelIndex],0.1,Color.BLUE)
	DebugDraw3D.draw_line(wheels[heighestSideWheelIndex],wheels[lowestSideWheelIndex],colorMode)
	
	DebugDraw3D.draw_line(wheels[0],wheels[1],colorMode)
	DebugDraw3D.draw_line(wheels[1],wheels[2],colorMode)
	DebugDraw3D.draw_line(wheels[2],wheels[3],colorMode)
	DebugDraw3D.draw_line(wheels[3],wheels[0],colorMode)
	
	DebugDraw3D.draw_sphere(center,0.1,Color.DEEP_SKY_BLUE)
	DebugDraw3D.draw_arrow(center, center + forward,Color.BLUE,0.1,true)
	DebugDraw3D.draw_arrow(center, center + left,Color.RED,0.1,true)
	DebugDraw3D.draw_arrow(center, center + up,Color.GREEN,0.1,true)
	
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
