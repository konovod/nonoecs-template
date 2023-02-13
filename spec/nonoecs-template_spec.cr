require "./spec_helper"

Spec.before_suite do
  systems = ECS::Systems.new(SPEC_WORLD)
    .add(BasicSystems.new(SPEC_WORLD))
    .add(GameSystems.new(SPEC_WORLD))

  systems.init
  systems.execute
  Engine.log("Starting spec suite...")
end

Spec.after_suite do
  Engine.log("Spec suite complete")
end

describe "app" do
  # TODO: Write tests

  it "works" do
    false.should eq(true)
  end
end
