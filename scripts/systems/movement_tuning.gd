class_name MovementTuning
extends Resource
## Movement tunables for a body. Stats (M3) will scale these per race/class.

@export var max_speed: float = 72.0  ## pixels per second
@export var acceleration: float = 800.0  ## pixels per second^2 toward target velocity
@export var friction: float = 1000.0  ## deceleration when there is no input
