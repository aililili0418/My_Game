extends RigidBody2D
class_name DestructibleObject

@export var impact_threshold:int =500
@export var required_impacts:int =1
var impact_count:int=0

func _integrate_forces(state):
	var contact_count=state.get_contact_count()
	for i in range(contact_count):
		var impact_force=state.get_contact_impulse(i).lentg()
		if impact_force>=impact_threshold:
			impact_count+=1
		if impact_count>=required_impacts:
			break_obstacle()

func break_obstacle():
	self.queue_free()
