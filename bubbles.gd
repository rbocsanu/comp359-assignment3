extends GPUParticles3D

@export var bubble_lifetime: float = 1.5
@export var float_speed_min: float = 0.5
@export var float_speed_max: float = 1.0
@export var bubble_texture: Texture2D

func _ready():
	# Set draw mode to billboard
	self.draw_passes = 3

	var mat = StandardMaterial3D.new()
	#mat.albedo_color = Color(1, 1, 1, 1)
	#mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	#mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	
	self.material_override = mat
	var process = ParticleProcessMaterial.new()
	process.direction = Vector3(0, 1, 0)  # upward
	process.spread = 30
	process.gravity = Vector3.ZERO
	process.set_param_min(ParticleProcessMaterial.Parameter.PARAM_INITIAL_LINEAR_VELOCITY, float_speed_min)
	process.set_param_max(ParticleProcessMaterial.Parameter.PARAM_INITIAL_LINEAR_VELOCITY, float_speed_max)

	self.process_material = process

	# Particle lifetime
	self.lifetime = bubble_lifetime

	# Emit once and auto-free
	self.one_shot = true
	#self.autofree = true
