module Engine
  alias Vec2 = StaticArray(Float32, 2)
  alias Vec3 = StaticArray(Float32, 3)
  alias Vec4 = StaticArray(Float32, 4)

  def vec2(x : Float32, y : Float32)
    Vec2[x, y]
  end

  def vec3(x : Float32, y : Float32, z : Float32)
    Vec3[x, y, z]
  end

  def vec4(x : Float32, y : Float32, z : Float32, w : Float32)
    Vec4[x, y, z, w]
  end

  private def vec2_default
    vec2(0, 0)
  end

  private def vec3_default
    vec3(0, 0, 0)
  end

  private def vec4_default
    vec4(0, 0, 0, 0)
  end

  alias Sampler2d = LibEngine::Texture

  private def sampler2D_default
    Sprite.new(0)
  end

  private def int_default
    0
  end

  private def float_default
    0.0f32
  end

  TYPES_MAPPING = {
    "vec2"      => "Vec2",
    "vec3"      => "Vec3",
    "vec4"      => "Vec4",
    "float"     => "Float32",
    "sampler2D" => "Sprite",
    "int"       => "Int32",
  }

  class UniformsArray(T, N)
    property! owner : Shader
    @id : LibEngine::ShaderUniform
    @data : StaticArray(T, N)

    def initialize(aid, value)
      @id = aid.unsafe_as(LibEngine::ShaderUniform)
      @data = StaticArray(T, N).new(value)
    end

    def []=(index, value)
      unsafe_set(index, value)
      apply
    end

    def [](index)
      @data[index]
    end

    def unsafe_set(index, value)
      @data[index] = T.new(value)
    end

    def apply
      LibEngine.uniform_set_ptr(owner.to_unsafe, @id, pointerof(@data))
    end
  end

  class Shader
    macro uniform(name, typ, id)
      @value_{{name.id}} : {{TYPES_MAPPING[typ.stringify].id}} = {{typ.id}}_default
      def {{name.id}}=(value : {{TYPES_MAPPING[typ.stringify].id}})
        @value_{{name.id}} = value
        {% if typ.id == :sampler2D %}
          LibEngine.uniform_set_texture(to_unsafe, {{id}}.unsafe_as(LibEngine::ShaderUniform), @value_{{name.id}})
        {% else %}
          LibEngine.uniform_set_ptr(to_unsafe, {{id}}.unsafe_as(LibEngine::ShaderUniform), pointerof(@value_{{name.id}}))
        {% end %}
      end

      def {{name.id}} : {{typ.stringify.capitalize.id}}
        @value_{{name.id}}
      end
    end

    macro uniform_array(name, count, typ, id)
      @value_{{name.id}} = UniformsArray({{TYPES_MAPPING[typ.stringify].id}}, {{count}}).new({{id}}, {{typ.id}}_default)

      def {{name.id}} 
        @value_{{name.id}}.owner = self
        @value_{{name.id}}
      end

    end

    macro attribute(name, typ, id)
    end

    def initialize(@data : Int32)
    end

    def to_unsafe
      @data.unsafe_as(LibEngine::Shader)
    end

    def activate
      LibEngine.shader_activate(self)
    end
  end

  class DefaultShader < Shader
    uniform screen_size, vec2, 0
    uniform tex, sampler2D, 1
    attribute color, vec4, 0
    attribute pos, vec3, 1
    attribute texpos, vec3, 2
  end

  #   fun vertex_list_add_field = VertexListAddField(list : VertexList, field : ShaderAttribute)
  #   fun vertex_list_add_padding = VertexListAddPadding(list : VertexList, n_bytes : Int32)
  #   fun vertex_list_copy = VertexListCopy(list : VertexList) : VertexList
  #   fun vertex_list_change = VertexListChange(list : VertexList, buffer : Void*, typ : VertexListPrimitive, n_vertices : Int32)
  DELETED_VERTEX_LIST = (-1).unsafe_as(LibEngine::VertexList)

  # TODO - vertex array
  enum VertexListPrimitive
    Points
    Lines
    Triangles
  end

  class VertexList
    @data : LibEngine::VertexList

    macro vertex(args)
      record Vertex, field : Int32
      VERTEX_SIZE = sizeof(Vertex)
      getter items = [] of Vertex
    end

    @typ : VertexListPrimitive

    def initialize(@typ, start_count = 128)
      @items.capacity = start_count
      @data = LibEngine.vertex_list_create(@items.to_unsafe, @typ, VERTEX_SIZE, start_count)
    end

    # TODO vertex list clone
    # def initialize(*, from_raw : LibEngine::VertexList)
    # end

    # def clone
    #   self.class.new(from_raw: LibEngine.vertex_list_copy(@data))
    # end

    def to_unsafe
      @data
    end

    def draw(*, limit_size : Int32? = nil, was_updated : Bool = False)
      LibEngine.vertex_list_draw(@data, limit_size || -1, was_updated)
    end

    def finalize
      free
    end

    def free
      return if @data.unsafe_as(Int32) < 0
      LibEngine.vertex_list_delete(to_unsafe)
      @data = DELETED_VERTEX_LIST
    end
  end
end
