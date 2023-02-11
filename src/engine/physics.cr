module Engine
  module Physics
    def self.reset
      LibEngine.physics_reset
    end
  end

  private MATERIAL_HASH = {} of Body.class => LibEngine::Material

  record MaterialData, density : Float64, friction : Float64, elasticity : Float64, def_radius : Float64
  private MATERIAL_DATA = {} of Body.class => MaterialData
  private MATERIAL_COLL = {} of Tuple(Body.class, Body.class) => LibEngine::CollisionType

  annotation Collides
  end

  # TODO - optimize not reading what is not needed

  struct CollisionData(X)
    getter data : X
    getter first : Bool
    getter pos : Vector2
    getter normal : Vector2
    getter energy : Float64
    getter impulse : Vector2

    def first?
      @first
    end

    def initialize(@data, @first, @pos, @normal, @energy, @impulse)
    end

    def self.try_new(body, with_mat)
      ptr = LibEngine.get_collisions(body, with_mat, out afirst, out ax, out ay, out nx, out ny, out aenergy, out aimpulsex, out aimpulsey)
      if ptr == LibEngine::NO_BODY_ID
        return nil
      else
        return self.new(ptr.unsafe_as(X), afirst, v2(ax, ay), v2(nx, ny), aenergy, v2(aimpulsex, aimpulsey))
      end
    end
  end

  class Polygon
    @raw : LibEngine::Polygon?

    def to_unsafe
      @raw.not_nil!
    end

    def initialize(points : Array(Vector2)? = nil)
      @raw = LibEngine.polygon_create(points ? points.size : 0)
      if points
        points.each do |v|
          LibEngine.polygon_add_point(to_unsafe, v.x, v.y)
        end
      end
    end

    def add_point(v)
      LibEngine.polygon_add_point(to_unsafe, v.x, v.y)
    end

    def draw(pos, a, color = Color::WHITE)
      LibEngine.polygon_draw(to_unsafe, pos.x, pos.y, a, color, -1.unsafe_as(LibEngine::Sprite), 0, 0, 1, 1)
    end

    def draw_textured(pos, a, tex : Texture, color = Color::WHITE, offset = v2(0, 0), scale = v2(1, 1))
      LibEngine.polygon_draw(to_unsafe, pos.x, pos.y, a, color, tex.to_unsafe, offset.x, offset.y, scale.x, scale.y)
    end

    def free
      if r = @raw
        LibEngine.polygon_free r
        @raw = nil
      end
    end

    def finalize
      free
    end
  end

  class Body
    @raw : LibEngine::Body?
    property x = 0f64
    property y = 0f64
    property vx = 0f64
    property vy = 0f64
    property angle = 0f64
    property omega = 0f64

    def to_unsafe
      @raw.not_nil!
    end

    def pos
      v2(self.x, self.y)
    end

    def update_coords(mode : LibEngine::PhysicCoordinatesMode = LibEngine::PhysicCoordinatesMode::ReadWrite)
      LibEngine.body_coords(to_unsafe, LibEngine::PhysicCoordinatesMode::ReadWrite, pointerof(@x), pointerof(@y), pointerof(@vx), pointerof(@vy), pointerof(@angle), pointerof(@omega))
    end

    def warp_to(*, x = nil, y = nil, vx = nil, vy = nil, angle = nil, omega = nil)
      @x = Float64.new(x) if x
      @y = Float64.new(y) if y
      @vx = Float64.new(vx) if vx
      @vy = Float64.new(vy) if vy
      @angle = Float64.new(angle) if angle
      @omega = Float64.new(omega) if omega
    end

    def initialize(@x = 0f64, @y = 0f64, @vx = 0f64, @vy = 0f64, @angle = 0f64, @omega = 0f64)
      @raw = LibEngine.body_create(MATERIAL_HASH[self.class], owner.unsafe_as(Pointer(Void)).unsafe_as(LibEngine::BodyID))
    end

    def owner
      self
    end

    def self.body_type
      LibEngine::BodyType::Dynamic
    end

    macro collide(klass)
    MATERIAL_COLL[{self, {{klass}}}] = LibEngine::CollisionType::Hit
  end

    macro detect_collide(klass, &)
    MATERIAL_COLL[{self, {{klass}}}] = LibEngine::CollisionType::HitDetect

    @[Collides(with: {{klass}}, processable: false)]
    def collision_{{@type}}_{{klass}}(coll)
      {{yield}} 
    end
  end

    macro can_collide(klass, &)
    MATERIAL_COLL[{self,  {{klass}}}] = LibEngine::CollisionType::Processable

    @[Collides(with: {{klass}}, processable: true)]
    def collision_{{@type}}_{{klass}}(coll)
      {{yield}} 
    end
  end

    macro pass(klass)
    MATERIAL_COLL[{self,  {{klass}}}] = LibEngine::CollisionType::Pass
  end

    macro detect_pass(klass, &)
    MATERIAL_COLL[{self,  {{klass}}}] = LibEngine::CollisionType::PassDetect
    @[Collides(with: {{klass}}, processable: false)]
    def collision_{{@type}}_{{klass}}(coll)
      {{yield}} 
    end
  end

    macro inherited
    {% verbatim do %}
      macro finished
        def process_all_collisions
          {% for x in @type.methods %}
            {% if x.annotation(Collides) %}
              {% ann = x.annotation(Collides) %}
                loop do
                  %coll = CollisionData({{ann[:with]}}).try_new(to_unsafe, MATERIAL_HASH[{{ann[:with]}}])
                  if %coll
                    result = {{x.name}}(%coll)
                    {% if ann[:processable] %}
                      LibEngine.set_current_collision_result(result)
                    {% end %}
                  else
                    break
                  end

                end  
            {% end %}  
          {% end %}
        end
      end
    {% end %}    
  end

    macro material(density, friction, elasticity, default_radius = 0)
    MATERIAL_DATA[self] = MaterialData.new({{density}}, {{friction}}, {{elasticity}}, {{default_radius}})
  end

    macro inherited
    # puts "registering #{self} as #{(MATERIAL_HASH.keys.size+1)}"
    MATERIAL_HASH[self] = (MATERIAL_HASH.keys.size+1).unsafe_as(LibEngine::Material)
  end

    def add_box(box)
      LibEngine.body_add_shape_box(to_unsafe, box.left, box.top, box.right, box.bottom)
    end

    def add_line(p1, p2)
      LibEngine.body_add_shape_line(to_unsafe, p1.x, p1.y, p2.x, p2.y)
    end

    def add_circle(offset, r)
      LibEngine.body_add_shape_circle(to_unsafe, offset.x, offset.y, r)
    end

    def add_poly(poly : Polygon)
      LibEngine.body_add_shape_poly(to_unsafe, poly.to_unsafe)
    end

    def apply_force(force, offset, torque)
      LibEngine.body_apply_force(to_unsafe, force.x, force.y, offset.x, offset.y, torque)
    end

    def apply_control(target, max_speed, max_force)
      LibEngine.body_apply_control(to_unsafe, target.x, target.y, max_speed, max_force)
    end

    def free
      if r = @raw
        LibEngine.body_free r
        @raw = nil
      end
    end

    def finalize
      free
    end

    def process
      update_coords
      process_all_collisions
    end
  end

  class StaticBody < Body
    def self.body_type
      LibEngine::BodyType::Static
    end
  end

  class KinematicBody < Body
    def self.body_type
      LibEngine::BodyType::Kinematic
    end
  end

  #   fun get_collisions = GetCollisions(body : Body, with_mat : Material, is_first : Bool*, x : PhysicsCoord*, y : PhysicsCoord*, nx : PhysicsCoord*, ny : PhysicsCoord*, energy : PhysicsCoord*, impulsex : PhysicsCoord*, impulsey : PhysicsCoord*) : Void*
  #   fun get_material_collisions = GetMaterialCollisions(mat : Material, with_mat : Material, body1 : Void*, body2 : Void*, is_first : Bool*, x : PhysicsCoord*, y : PhysicsCoord*, nx : PhysicsCoord*, ny : PhysicsCoord*, energy : PhysicsCoord*, impulsex : PhysicsCoord*, impulsey : PhysicsCoord*) : Bool
  #   fun set_current_collision_result = SetCurrentCollisionResult(should_hit : Bool)

  def self.init(dir)
    LibEngine.init dir
    MATERIAL_HASH.each do |k, v|
      next if k == StaticBody
      next if k == KinematicBody
      data = MATERIAL_DATA[k]
      typ = k.body_type
      LibEngine.material(v, data.density, data.friction, data.elasticity, typ, data.def_radius)
    end
    MATERIAL_COLL.each do |k, v|
      LibEngine.material_collisions(MATERIAL_HASH[k[0]], MATERIAL_HASH[k[1]], v)
    end
  end
end
