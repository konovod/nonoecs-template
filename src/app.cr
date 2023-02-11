require "./engine/engine.cr"
require "./resources.cr"
require "myecs"

require "./utils/*"
require "./game_config"
require "./game_systems"

@[ECS::SingleFrame(check: false)]
struct QuitEvent < ECS::Component
end

{% unless flag? :dont_run %}
  begin
    world = ECS::World.new
    systems = ECS::Systems.new(world)
      .add(BasicSystems.new(world))
      .add(GameSystems.new(world))

    systems.init
    quitter = world.of(QuitEvent)
    loop do
      systems.execute
      break if !quitter.empty?
    end
    systems.teardown
  rescue ex : Exception
    Engine.log(ex.inspect_with_backtrace)
  end
{% end %}
ECS.debug_stats
