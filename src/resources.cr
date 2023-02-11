include Engine

THE_SCREEN     = Sprite.new(-1)
NO_MUSIC       = Sound.new(-1)
DEFAULT_SHADER = DefaultShader.new(0)
ALL_SHADERS    = ShaderAllShaders.new(-1)

module RES
  Config = RawResource.new(0)
  Font   = FontResource.new(0)
end

class ShaderAllShaders < Shader
  uniform screen_size, vec2, 0
  uniform tex, sampler2D, 1
  attribute color, vec4, 0
  attribute pos, vec3, 1
  attribute texpos, vec3, 2
end
