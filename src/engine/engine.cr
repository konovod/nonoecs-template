require "./libnonoengine"
require "./vector2"
require "./aabb"
require "./physics"
require "./shaders"
require "./gui"

module Engine
  extend self
  enum Params
    Fullscreen
    Width
    Height
    VSync
    Antialias
    UseLog
    Autoscale
    Volume
    ClearColor
    PhysicsSpeed
    GravityX
    GravityY
    Damping
    ProgressWidth
    ProgressHeight
    ProgressX
    ProgressY
    RealWidth      = 100
    RealHeight     = 101
    FPS            = 102
    DeltaTime      = 103
  end

  def self.[]=(param : Params, value)
    LibEngine.set(LibEngine::EngineValue.new(param.to_i), value)
  end

  def self.[](param : Params)
    LibEngine.get(LibEngine::EngineValue.new(param.to_i))
  end

  def self.screen_size
    v2(self[Params::RealWidth], self[Params::RealHeight])
  end

  def self.screen_box
    aabb(v2(0, 0), v2(self[Params::RealWidth], self[Params::RealHeight]))
  end

  class RawResource
    @data : LibEngine::RawResource

    def initialize(adata)
      @data = adata.unsafe_as(LibEngine::RawResource)
    end

    def to_unsafe
      @data
    end

    def as_bytes
      ptr = LibEngine.raw_resource(@data, out size)
      Bytes.new(ptr.as(Pointer(UInt8)), size)
    end

    def as_string
      String.new(as_bytes)
    end
  end

  def process
    LibEngine.process
    GUI.reset
  end

  def log(s)
    LibEngine.log(s.to_s.to_unsafe)
  end

  class Sprite
    @data : LibEngine::Sprite

    def initialize(adata)
      @data = adata.unsafe_as(LibEngine::Sprite)
    end

    def to_unsafe
      @data
    end

    def draw(pos : Vector2, scale : Vector2 = v2(1, 1), angle = 0.0, color = Color::WHITE)
      LibEngine.sprite(to_unsafe, pos.x, pos.y, scale.x, scale.y, angle, color)
    end

    def draw_sliced(box : AABB, color = Color::WHITE)
      LibEngine.sprite_sliced(to_unsafe, box.v0.x, box.v0.y, box.size.x, box.size.y, color)
    end

    def background(scale = v2(1, 1), offset = v2(0, 0), color = Color::WHITE)
      LibEngine.background(to_unsafe, scale.x, scale.y, offset.x, offset.y, color)
    end

    def tex_triangle(p1, t1, p2, t2, p3, t3)
      LibEngine.textured_triangle(to_unsafe, p1.x, p1.y, t1.x, t1.y, p2.x, p2.y, t2.x, t2.y, p3.x, p3.y, t3.x, t3.y)
    end

    def tex_triangle(p1, p2, p3, offset = v2(0, 0), scale = v2(1, 1))
      LibEngine.textured_triangle(to_unsafe,
        p1, offset,
        p2, offset + (p2 - p1) * scale,
        p3, offset + (p3 - p1)*scale)
    end

    def tex_rect(box : AABB, offset = v2(0, 0), scale = v2(1, 1))
      tex_triangle(box.topleft, box.topright, box.bottomright, offset, scale)
      tex_triangle(box.topleft, box.bottomleft, box.bottomright, offset, scale)
    end

    def get_pixel(p)
      LibEngine.get_pixel(p.x, p.y, to_unsafe)
    end

    def clone
      Texture.new(raw: LibEngine.texture_clone(to_unsafe))
    end
  end

  # struct Texture < Sprite
  # end

  struct TileMap
    @data : Int32

    def initialize(@data)
    end

    def to_unsafe
      @data.unsafe_as(LibEngine::TileMap)
    end

    def draw_frame(frame, pos : Vector2, scale = v2(1, 1), angle = 0.0, color = Color::WHITE)
      LibEngine.draw_tiled(to_unsafe, frame, pos.x, pos.y, scale.x, scale.y, angle, color)
    end
  end

  class Sound
    @data : Int32
    @volume = 100.0f32

    def initialize(@data)
    end

    def to_unsafe
      @data.unsafe_as(LibEngine::Sound)
    end

    def clone
      Sound.new(@data)
    end

    def play(data = self.as(Void*), volume = @volume)
      LibEngine.play(to_unsafe, volume, data)
    end

    def music(volume = @volume)
      LibEngine.music(to_unsafe, volume)
    end

    def playing?(data = self.as(Void*))
      LibEngine.sound_playing(to_unsafe, data)
    end
  end

  enum VAlign
    None
    Top
    Center
    Bottom
    Flow
  end
  enum HAlign
    None
    Left
    Center
    Right
    Flow
  end

  module FontDrawText
    def draw_text(text, pos : Vector2)
      LibEngine.draw_text(to_unsafe, text, pos.x, pos.y)
    end

    def draw_text_boxed(text, box : AABB, halign : HAlign = HAlign::Left, valign : VAlign = VAlign::Center)
      LibEngine.draw_text_boxed(to_unsafe, text, box.v0.x, box.v0.y, box.size.x, box.size.y, LibEngine::HAlign.new(halign.to_i), LibEngine::VAlign.new(valign.to_i))
    end

    def measure(text)
      LibEngine.measure_text(to_unsafe, text, out x, out y)
      v2(x, y)
    end
  end

  struct FontResource
    @data : Int32

    def initialize(@data)
    end

    def to_unsafe
      @data.unsafe_as(LibEngine::Font)
    end

    include FontDrawText
  end

  struct Font
    BOLD       = 1
    ITALIC     = 2
    UNDERLINED = 4

    @data : LibEngine::FontInstance

    def to_unsafe
      @data.unsafe_as(LibEngine::FontInstance)
    end

    @char_size = 24
    @color = Engine::Color::WHITE
    @styles = 0
    @kx = 1.0f32
    @ky = 1.0f32

    def initialize(res : FontResource, *, @char_size = 24, @color = Engine::Color::WHITE, @styles = 0, @kx = 1, @ky = 1)
      @data = LibEngine.font_create(res.to_unsafe, @char_size, @color, LibEngine::FontStyle.new(@styles), @kx, @ky)
    end

    def initialize(res : FontResource, *, dont_create : Bool)
      if dont_create
        @data = res.to_unsafe
      else
        @data = LibEngine.font_create(res.to_unsafe, @char_size, @color, LibEngine::FontStyle.new(@styles), @kx, @ky)
      end
    end

    private def update_config
      LibEngine.font_config(@data, @char_size, @color, LibEngine::FontStyle.new(@styles), @kx, @ky)
    end

    def char_size=(value)
      @char_size = value
      update_config
    end

    def color=(value)
      @color = value
      update_config
    end

    def styles=(value)
      @styles = value
      update_config
    end

    def kx=(value)
      @kx = value
      update_config
    end

    def ky=(value)
      @ky = value
      update_config
    end

    include FontDrawText
  end

  LAYER_GUI = 100

  def self.layer=(value)
    LibEngine.layer(value)
  end

  def camera(offset = v2(0, 0), scale = v2(1, 1), angle = 0)
    LibEngine.camera(offset.x, offset.y, scale.x, scale.y, angle)
  end

  enum Color : UInt32
    BLACK      = 0x000000FF
    MAROON     = 0x800000FF
    GREEN      = 0x008000FF
    OLIVE      = 0x808000FF
    NAVY       = 0x000080FF
    PURPLE     = 0x800080FF
    TEAL       = 0x008080FF
    GRAY       = 0x808080FF
    SILVER     = 0xC0C0C0FF
    RED        = 0xFF0000FF
    LIME       = 0x00FF00FF
    YELLOW     = 0xFFFF00FF
    BLUE       = 0x0000FFFF
    FUCHSIA    = 0xFF00FFFF
    AQUA       = 0x00FFFFFF
    WHITE      = 0xFFFFFFFF
    MONEYGREEN = 0xC0DCC0FF
    SKYBLUE    = 0xA6CAF0FF
    CREAM      = 0xFFFBF0FF
    MEDGRAY    = 0xA0A0A4FF
  end

  def color(r : Int32, g : Int32, b : Int32, a : Int32 = 255) : Engine::Color
    Color.new((UInt32.new(r) << 24) + (UInt32.new(g) << 16) + (UInt32.new(b) << 8) + (UInt32.new(a) << 0))
  end

  def color(u : UInt32) : Engine::Color
    Color.new(u)
  end

  def line(p1, p2, color1, color2 = color1)
    LibEngine.line(p1.x, p1.y, p2.x, p2.y, color1, color2)
  end

  def line_settings(width = 1, stipple = 0xFFFFFFFF, stipple_scale = 1)
    LibEngine.line_settings(width, stipple, stipple_scale)
  end

  def ellipse(center, radius, filled, color1, color2 = color1, angle = 0)
    LibEngine.ellipse(center.x, center.y, radius.x, radius.y, filled, color1, color2, angle)
  end

  def circle(center, r, filled, color1, color2 = color1)
    LibEngine.ellipse(center.x, center.y, r, r, filled, color1, color2, 0)
  end

  def rect(box, filled, color1, color2, color3, color4, angle = 0)
    LibEngine.rect box.left, box.top, box.width, box.height, filled, color1, color2, color3, color4, angle
  end

  def rect(box, filled, color, angle = 0)
    LibEngine.rect box.left, box.top, box.width, box.height, filled, color, color, color, color, angle
  end

  def rect_gauge(box, value, color1, color2, angle = 0)
    LibEngine.rect box.left, box.top, box.width, box.height, true, color2, color2, color2, color2, angle
    LibEngine.rect box.left, box.top, box.width*value, box.height, true, color1, color1, color1, color1, angle
  end

  def point(pos : Vector2, color)
    LibEngine.point(pos.x, pos.y, color)
  end

  def triangle(p1 : Vector2, color1, p2 : Vector2, color2, p3 : Vector2, color3)
    LibEngine.triangle p1.x, p1.y, color1, p2.x, p2.y, color2, p3.x, p3.y, color3
  end

  def triangle(p1 : Vector2, p2 : Vector2, p3 : Vector2, color)
    LibEngine.triangle p1.x, p1.y, color, p2.x, p2.y, color, p3.x, p3.y, color
  end

  alias Key = LibEngine::Key

  module Keys
    def self.[](x)
      LibEngine.key_state(x)
    end
  end

  enum MouseButtonState
    Up
    Down
    Clicked
  end

  module Mouse
    def self.x
      LibEngine.mouse_get(LibEngine::MouseAxis::X)
    end

    def self.y
      LibEngine.mouse_get(LibEngine::MouseAxis::Y)
    end

    def self.pos
      v2(self.x, self.y)
    end

    def self.scaled_x
      LibEngine.mouse_get(LibEngine::MouseAxis::ScaledX)
    end

    def self.scaled_y
      LibEngine.mouse_get(LibEngine::MouseAxis::ScaledY)
    end

    def self.scaled_pos
      v2(self.scaled_x, self.scaled_y)
    end

    def self.scroll
      LibEngine.mouse_get(LibEngine::MouseAxis::Scroll)
    end

    def self.left
      MouseButtonState.new(LibEngine.mouse_state(LibEngine::MouseButton::Left).to_i)
    end

    def self.right
      MouseButtonState.new(LibEngine.mouse_state(LibEngine::MouseButton::Right).to_i)
    end

    def self.middle
      MouseButtonState.new(LibEngine.mouse_state(LibEngine::MouseButton::Middle).to_i)
    end
  end

  DELETED_TEXTURE = (-1).unsafe_as(LibEngine::Sprite)

  class Texture < Sprite
    @width : Int32?
    @height : Int32?
    @pixels_as_byte : Slice(UInt32)?
    @pixels_as_float : Slice(Float32)?
    @is_floating : Bool

    def render_to
      LibEngine.render_to(to_unsafe)
    end

    def initialize(@width, @height, *, @is_floating = false)
      @data = LibEngine.texture_create(width, height)
    end

    def from_gpu
      if @is_floating
        ptr = LibEngine.texture_get_pixels(@data, out w, out h, LibEngine::PixelFormat::AsFloat).as(Float32*)
        @pixels_as_float = ptr.to_slice(w.to_i*h.to_i*4)
      else
        ptr = LibEngine.texture_get_pixels(@data, out w, out h, LibEngine::PixelFormat::AsByte).as(UInt32*)
        @pixels_as_byte = ptr.to_slice(w.to_i*h.to_i)
      end
      @width = w.to_i
      @height = h.to_i
    end

    def to_gpu
      if @is_floating
        return unless ptr = @pixels_as_float
        LibEngine.texture_load_pixels(to_unsafe, ptr, LibEngine::PixelFormat::AsFloat)
      else
        return unless ptr = @pixels_as_byte
        LibEngine.texture_load_pixels(to_unsafe, ptr, LibEngine::PixelFormat::AsByte)
      end
    end

    def initialize(*, raw : LibEngine::Sprite, @is_floating = false)
      @data = raw
    end

    def finalize
      free
    end

    def free
      return if @data.unsafe_as(Int32) < 0
      LibEngine.texture_delete(to_unsafe)
      @data = DELETED_TEXTURE
    end

    def save(filename)
      LibEngine.texture_save(to_unsafe, filename)
    end

    def capture_screen(x, y, width, height)
      LibEngine.capture_screen(x, y, width, height, to_unsafe)
    end

    def self.from_screen(x = 0, y = 0, width = Engine[Params::Width], height = Engine[Params::Height])
      new(width, height).tap do |tex|
        tex.capture_screen(x, y, width, height)
      end
    end

    # TODO - api to get size without loading pixels?
    def width
      unless w = @width
        from_gpu
        w = @width.not_nil!
      end
      w
    end

    def height
      unless h = @height
        from_gpu
        h = @height.not_nil!
      end
      h
    end

    def pixels_as_float : Slice(Float32)
      unless ptr = @pixels_as_float
        @is_floating = true
        from_gpu
        ptr = @pixels_as_float.not_nil!
      end
      ptr
    end

    def pixels_as_int : Slice(UInt32)
      unless ptr = @pixels_as_byte
        @is_floating = false
        from_gpu
        ptr = @pixels_as_byte.not_nil!
      end
      ptr
    end
  end
end
