class GameSystems < ECS::Systems
  def initialize(@world)
    super
    add KeyReactSystem.new(@world, pressed: CONFIG_PRESSED, down: CONFIG_DOWN)
  end
end
