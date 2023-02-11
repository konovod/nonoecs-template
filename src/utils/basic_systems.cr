class BasicSystems < ECS::Systems
  def initialize(@world)
    super
    add EngineSystem.new(world)
    add ShouldQuitSystem.new(world)
    add CameraSystem.new(world)
    add RenderSystem.new(world)
  end
end

class EngineSystem < ECS::System
  def init
    Engine[Engine::Params::Antialias] = 0
    Engine[Engine::Params::VSync] = 1
    Engine[Engine::Params::Width] = 1024
    Engine[Engine::Params::Height] = 768
    # Engine[Engine::Params::ClearColor] = 0
    Engine.init "resources"
    GameConfig.init_config
  end

  def execute
    Engine.process
  end
end

record RenderSprite < ECS::Component, image : Engine::Sprite, offset : Vector2
record RenderTile < ECS::Component, image : Engine::TileMap, frame : Int32, offset : Vector2
record RenderPosition < ECS::Component, pos : Vector2
record RenderRotation < ECS::Component, angle : Float32 = 0
record RenderScale < ECS::Component, scale : Vector2
record RenderLayer < ECS::Component, layer : Int32 = 1
record RenderColor < ECS::Component, color : Engine::Color

class RenderSystem < ECS::System
  def filter(world)
    world.of(RenderPosition).any_of([RenderSprite, RenderTile])
  end

  def process(entity)
    pos = entity.getRenderPosition

    if cscale = entity.getRenderScale?
      scale = cscale.scale
    else
      scale = v2(1, 1)
    end
    if rotation = entity.getRenderRotation?
      angle = rotation.angle
    else
      angle = 0.0
    end
    if layer = entity.getRenderLayer?
      Engine.layer = layer.layer
    else
      Engine.layer = 1
    end
    if colorize = entity.getRenderColor?
      color = colorize.color
    else
      color = Color::WHITE
    end
    if spr = entity.getRenderSprite?
      spr.image.draw pos.pos + spr.offset, scale, angle, color
    end
    if tile = entity.getRenderTile?
      tile.image.draw_frame tile.frame, pos.pos + tile.offset, scale, angle, color
    end
  end
end

class ShouldQuitSystem < ECS::System
  def execute
    @world.new_entity.add(QuitEvent.new) if !Engine::Keys[Key::Quit].up?
  end
end

alias KeysConfig = Hash(Engine::Key, ECS::Component)

class KeyReactSystem < ECS::System
  @ent : ECS::Entity

  def initialize(@world : ECS::World, *, @pressed = KeysConfig.new, @down = KeysConfig.new)
    @ent = @world.new_entity
  end

  def execute
    @pressed.each do |key, ev|
      if Engine::Keys[key].pressed?
        @ent.set(ev)
      end
    end
    @down.each do |key, ev|
      if !Engine::Keys[key].up?
        @ent.set(ev)
      end
    end
  end
end

@[ECS::Singleton]
record CameraPosition < ECS::Component, offset : Vector2 = Vector2.zero, scale : Vector2 = v2(1, 1), angle : Float32 = 0 do
  def move(vector)
    return CameraPosition.new(offset + vector, scale, @angle)
  end

  def scale(k)
    return CameraPosition.new(offset, scale*k, @angle)
  end

  def rotate(angle)
    return CameraPosition.new(offset, scale, @angle + angle)
  end
end

class CameraSystem < ECS::System
  def init
    @world.new_entity.add(CameraPosition.new)
  end

  def execute
    pos = @world.new_entity.getCameraPosition
    Engine.camera(pos.offset, pos.scale, pos.angle)
  end
end
