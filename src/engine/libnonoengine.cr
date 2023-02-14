@[Link("nonoengine")]
lib LibEngine
  alias Coord = Float32
  alias Color = UInt32
  alias String = UInt8*
  type RawResource = Int32
  type Sprite = Int32
  type Sound = Int32
  type Button = Int32
  type TileMap = Int32
  type Font = Int32
  alias FontInstance = Font
  type Panel = Int32
  type Shader = Int32
  type ShaderUniform = Int32
  type ShaderAttribute = Int32
  alias Texture = Sprite
  type VertexList = Int32
  alias PhysicsCoord = Float64
  type Body = Int32
  type BodyID = Int64
  NO_BODY_ID = -1i64
  type Material = Int32
  type Polygon = Int32

  enum Key
    A; B; C; D; E; F; G; H
    I; J; K; L; M; N; O; P
    Q; R; S; T; U; V; W; X
    Y; Z
    Num0; Num1; Num2; Num3; Num4
    Num5; Num6; Num7; Num8; Num9

    Escape
    LControl; LShift; LAlt; LSystem
    RControl; RShift; RAlt; RSystem
    Menu
    LBracket  # [
    RBracket  # ]
    SemiColon # ;
    Comma     # ,
    Period    # .
    Quote     # '
    Slash     # /
    BackSlash # \
    Tilde     # ~
    Equal     # =
    Dash      # -
    Space
    Return
    Backspace
    Tab
    PageUp
    PageDown
    End
    Home
    Insert
    Delete
    Add      # +
    Subtract # -
    Multiply # *
    Divide   # /
    Left     # Left arrow
    Right    # Right arrow
    Up       # Up arrow
    Down     # Down arrow
    Numpad0; Numpad1; Numpad2; Numpad3; Numpad4
    Numpad5; Numpad6; Numpad7; Numpad8; Numpad9
    F1; F2; F3; F4; F5; F6; F7; F8
    F9; F10; F11; F12; F13; F14; F15
    Pause

    # special keys

    Quit = -1
    Any  = -2
  end

  enum MouseButton
    Left
    Right
    Middle
  end

  enum MouseAxis
    X
    Y
    Scroll
    ScaledX
    ScaledY
  end

  enum KeyState
    Up
    Down
    Pressed
  end

  enum MouseButtonState
    Up
    Down
    Clicked
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

  enum EngineValue
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
  # TEngineConfig = Fullscreen..ClearColor;

  @[Flags]
  enum FontStyle
    Bold
    Italic
    Underlined
  end

  enum ButtonState
    Normal
    Hover
    Pressed
    Clicked
  end

  enum GUICoord
    X
    Y
    Width
    Height
    MouseX
    MouseY
  end

  enum PathfindAlgorithm
    AStarNew
    AStarReuse
    DijkstraNew
    DijkstraReuse
  end
  type PathfindCallback = (Float32, Float32, Float32, Float32, Void* -> Float32)

  enum PixelFormat
    AsByte
    AsFloat
  end

  enum VertexListPrimitive
    Points
    Lines
    Triangles
  end

  enum PhysicCoordinatesMode
    Read
    Write
    ReadWrite
    Increment
  end

  enum BodyType
    Dynamic
    Static
    Kinematic
    NonRotating
  end

  enum CollisionType
    Pass
    Hit
    PassDetect
    HitDetect
    Processable
  end

  # Общие функции движка

  fun init = EngineInit(resources : String)
  fun set = EngineSet(param : EngineValue, value : Int32)
  fun get = EngineGet(param : EngineValue) : Int32
  fun process = EngineProcess
  fun raw_resource = RawResource(resource : RawResource, size : Int32*) : Void*
  fun raw_texture = RawTexture(resource : Sprite) : UInt32 # returns opengl handle
  fun log = EngineLog(s : String)
  fun free = EngineFree

  # Обработка ввода

  fun key_state = KeyState(key : Key) : KeyState
  fun mouse_get = MouseGet(axis : MouseAxis) : Coord
  fun mouse_state = MouseState(key : MouseButton) : MouseButtonState

  # 2д-рендер - спрайты

  fun sprite = Sprite(sprite : Sprite, x : Coord, y : Coord, kx : Float32, ky : Float32, angle : Float32, color : Color)
  fun sprite_sliced = SpriteSliced(sprite : Sprite, x : Coord, y : Coord, w : Float32, h : Float32, color : Color)
  fun draw_tiled = DrawTiled(tiled : TileMap, frame : Int32, x : Coord, y : Coord, kx : Float32, ky : Float32, angle : Float32, color : Color)
  fun background = Background(sprite : Sprite, kx : Float32, ky : Float32, dx : Float32, dy : Float32, color : Color)

  # 2д-рендер - примитивы

  fun line = Line(x1 : Coord, y1 : Coord, x2 : Coord, y2 : Coord, color1 : Color, color2 : Color)
  # procedure Line(x1, y1, x2, y2: TCoord; color: TColor); overload;
  fun line_settings = LineSettings(width : Float32, stipple : UInt32, stipple_scale : Float32)
  fun ellipse = Ellipse(x : Coord, y : Coord, rx : Coord, ry : Coord, filled : Bool, color1 : Color, color2 : Color, angle : Float32)
  fun rect = Rect(x0 : Coord, y0 : Coord, w : Coord, h : Coord, filled : Bool, color1 : Color, color2 : Color, color3 : Color, color4 : Color, angle : Float32)
  fun point = Point(x : Coord, y : Coord, color : Color)
  fun triangle = Triangle(x1 : Coord, y1 : Coord, color1 : Color, x2 : Coord, y2 : Coord, color2 : Color, x3 : Coord, y3 : Coord, color3 : Color)

  fun textured_triangle = TexturedTriangle(sprite : Sprite, x1 : Coord, y1 : Coord, tx1 : Coord, ty1 : Coord, x2 : Coord, y2 : Coord, tx2 : Coord, ty2 : Coord, x3 : Coord, y3 : Coord, tx3 : Coord, ty3 : Coord)

  # 2д-рендер - дополнительные функции

  fun layer = SetLayer(z : Int32)
  fun camera = Camera(dx : Coord, dy : Coord, kx : Float32, ky : Float32, angle : Float32)

  # 2д-рендер - вывод текста

  fun font_config = FontConfig(font : FontInstance, char_size : Int32, color : Color, styles : FontStyle, kx : Float32, ky : Float32)
  fun font_create = FontCreate(font : Font, char_size : Int32, color : Color, styles : FontStyle, kx : Float32, ky : Float32) : FontInstance
  fun draw_text = DrawText(font : FontInstance, text : String, x : Coord, y : Coord)
  fun draw_text_boxed = DrawTextBoxed(font : FontInstance, text : String, x : Coord, y : Coord, w : Coord, h : Coord, halign : HAlign, valign : VAlign)
  fun measure_text = MeasureText(font : FontInstance, text : String, width : Coord*, height : Coord*)

  # ГУИ

  fun panel = Panel(id : Panel, parent : Panel, x : Coord, y : Coord, w : Coord, h : Coord, halign : HAlign, valign : VAlign)
  fun button = Button(btn : Button, parent : Panel, x : Coord, y : Coord, w : Coord, h : Coord, halign : HAlign, valign : VAlign, text : String, font : FontInstance, data : Void*) : ButtonState
  fun input_int = InputInt(value : Int32, min : Int32, max : Int32, parent : Panel, x : Coord, y : Coord, w : Coord, h : Coord, halign : HAlign, valign : VAlign, font : FontInstance, active : Bool*, data : Void*) : Int32
  fun gui_coord = GetGUICoord(coord : GUICoord) : Coord

  # Звук

  fun play = Play(sound : Sound, volume : Float32, data : Void*)
  fun music = Music(sound : Sound, volume : Float32)
  fun sound_playing = SoundPlaying(sound : Sound, data : Void*) : Bool

  # Поиск пути
  fun pathfind = Pathfind(size_x : Int32, size_y : Int32, algorithm : PathfindAlgorithm, diagonal_cost : Float32,
                          fromx : Int32, fromy : Int32, tox : Int32, toy : Int32,
                          x : Int32*, y : Int32*,
                          callback : PathfindCallback, opaque : Void*)

  # физика
  fun physics_reset = PhysicsReset
  fun body_create = BodyCreate(material : Material, data : BodyID) : Body
  fun body_free = BodyFree(body : Body)
  fun body_add_shape_circle = BodyAddShapeCircle(body : Body, dx : PhysicsCoord, dy : PhysicsCoord, r : PhysicsCoord)
  fun body_add_shape_box = BodyAddShapeBox(body : Body, x1 : PhysicsCoord, y1 : PhysicsCoord, x2 : PhysicsCoord, y2 : PhysicsCoord)
  fun body_add_shape_line = BodyAddShapeLine(body : Body, x1 : PhysicsCoord, y1 : PhysicsCoord, x2 : PhysicsCoord, y2 : PhysicsCoord)
  fun body_apply_force = BodyApplyForce(body : Body, fx : PhysicsCoord, fy : PhysicsCoord, dx : PhysicsCoord, dy : PhysicsCoord, torque : PhysicsCoord)
  fun body_apply_control = BodyApplyControl(body : Body, tx : PhysicsCoord, ty : PhysicsCoord, max_speed : PhysicsCoord, max_force : PhysicsCoord)
  fun body_coords = BodyCoords(body : Body, mode : PhysicCoordinatesMode, x : PhysicsCoord*, y : PhysicsCoord*, vx : PhysicsCoord*, vy : PhysicsCoord*, a : PhysicsCoord*, omega : PhysicsCoord*)
  fun material = Material(material : Material, density : Float64, friction : Float64, elasticity : Float64, special_type : BodyType, def_radius : Float64)
  fun material_collisions = MaterialCollisions(first : Material, second : Material, collision_type : CollisionType)
  fun get_collisions = GetCollisions(body : Body, with_mat : Material, is_first : Bool*, x : PhysicsCoord*, y : PhysicsCoord*, nx : PhysicsCoord*, ny : PhysicsCoord*, energy : PhysicsCoord*, impulsex : PhysicsCoord*, impulsey : PhysicsCoord*) : BodyID
  fun get_material_collisions = GetMaterialCollisions(mat : Material, with_mat : Material, body1 : BodyID*, body2 : BodyID*, is_first : Bool*, x : PhysicsCoord*, y : PhysicsCoord*, nx : PhysicsCoord*, ny : PhysicsCoord*, energy : PhysicsCoord*, impulsex : PhysicsCoord*, impulsey : PhysicsCoord*) : Bool
  fun set_current_collision_result = SetCurrentCollisionResult(should_hit : Bool)

  fun debug_physics_render = DebugPhysicsRender

  # физикаЖ полигоны
  fun polygon_create = PolygonCreate(capacity : Int32) : Polygon
  fun polygon_free = PolygonFree(poly : Polygon)
  fun polygon_add_point = PolygonAddPoint(poly : Polygon, x : PhysicsCoord, y : PhysicsCoord)
  fun polygon_draw = PolygonDraw(poly : Polygon, x : Coord, y : Coord, angle : Coord, c : Color, sprite : Texture, dx : Coord, dy : Coord, kx : Coord, ky : Coord)
  fun body_add_shape_poly = BodyAddShapePoly(body : Body, poly : Polygon)

  # шейдеры
  fun shader_activate = ShaderActivate(shader : Shader)
  fun shader_handle = ShaderHandle(shader : Shader) : UInt32
  fun uniform_set_int = UniformSetInt(shader : Shader, uniform : ShaderUniform, value : Int32)
  fun uniform_set_float = UniformSetFloat(shader : Shader, uniform : ShaderUniform, value : Float32)
  fun uniform_set_texture = UniformSetTexture(shader : Shader, uniform : ShaderUniform, value : Texture)
  fun uniform_set_ptr = UniformSetPtr(shader : Shader, uniform : ShaderUniform, value : Void*)

  # Пользовательские текстуры
  fun render_to = RenderTo(sprite : Texture)
  fun get_pixel = GetPixel(x : Coord, y : Coord, sprite : Texture) : Color
  fun texture_create = TextureCreate(width : Coord, height : Coord) : Texture
  fun texture_clone = TextureClone(texture : Texture) : Texture
  fun texture_delete = TextureDelete(texture : Texture)
  fun texture_save = TextureSave(texture : Texture, filename : String)
  fun capture_screen = CaptureScreen(x : Coord, y : Coord, width : Coord, height : Coord, dest : Texture)
  fun texture_get_pixels = TextureGetPixels(texture : Texture, width : Coord*, height : Coord*, format : PixelFormat) : Void*
  fun texture_load_pixels = TextureLoadPixels(texture : Texture, value : Void*, format : PixelFormat)

  # буферы вершин
  fun vertex_list_create = VertexListCreate(buffer : Void*, typ : VertexListPrimitive, vertex_size : Int32, n_vertices : Int32) : VertexList
  fun vertex_list_add_field = VertexListAddField(list : VertexList, field : ShaderAttribute)
  fun vertex_list_add_padding = VertexListAddPadding(list : VertexList, n_bytes : Int32)
  fun vertex_list_draw = VertexListDraw(list : VertexList, size : Int32, was_updated : Bool)
  fun vertex_list_copy = VertexListCopy(list : VertexList) : VertexList
  fun vertex_list_delete = VertexListDelete(list : VertexList)
  fun vertex_list_change = VertexListChange(list : VertexList, buffer : Void*, typ : VertexListPrimitive, n_vertices : Int32)
end
