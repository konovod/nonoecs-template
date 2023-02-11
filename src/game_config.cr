require "yaml"

CONFIG_PRESSED = KeysConfig.new
CONFIG_PRESSED[Engine::Key::Escape] = QuitEvent.new

CONFIG_DOWN = KeysConfig.new

enum F
  Main
end

Fonts = {} of F => Engine::Font

def init_fonts
  Fonts[F::Main] = Font.new(RES::Font, char_size: 16, color: Color::WHITE)
end

class GameConfig
  include YAML::Serializable

  getter dummy_param : Int32

  @@instance : GameConfig?

  def self.instance
    @@instance.not_nil!
  end

  def self.init_config
    @@instance = GameConfig.from_yaml(RES::Config.as_string)
    @@instance.not_nil!.patch
    init_fonts
  end

  def patch
  end
end

def cfg
  GameConfig.instance
end

def fnt
  Fonts[F::Main]
end
