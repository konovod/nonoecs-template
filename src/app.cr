require "./engine/engine.cr"
require "./resources.cr"
require "myecs"

require "./utils/*"
require "./game_config"
require "./game_systems"

@[ECS::SingleFrame(check: false)]
struct QuitEvent < ECS::Component
end

{% unless flag? :spec %}
  begin
    world = ECS::World.new
    systems = ECS::Systems.new(world)
      .add(BasicSystems.new(world))
      .add(GameSystems.new(world))

    systems.init
    loop do
      systems.execute
      break if world.component_exists?(QuitEvent)
    end
    systems.teardown
  rescue ex : Exception
    {% if flag? :release %}
    Engine.log(ex.inspect_with_backtrace)
    {% else %}
    puts ex.inspect_with_backtrace
    {% end %}
  end
{% end %}
ECS.debug_stats
