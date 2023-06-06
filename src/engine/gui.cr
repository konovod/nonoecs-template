module Engine
  record PanelMetrics, box : AABB, cursor : Vector2 do
    def self.read_from_engine
      PanelMetrics.new(
        box: aabb(v2(LibEngine.gui_coord(LibEngine::GUICoord::X), LibEngine.gui_coord(LibEngine::GUICoord::Y)),
          v2(LibEngine.gui_coord(LibEngine::GUICoord::Width), LibEngine.gui_coord(LibEngine::GUICoord::Height))),
        cursor: v2(LibEngine.gui_coord(LibEngine::GUICoord::MouseX), LibEngine.gui_coord(LibEngine::GUICoord::MouseY))
      )
    end
  end

  class GUI
    @@panel_counter = 0
    @@panel_parent = 0
    @@button_counter = 0
    # TODO - screen size
    @@metrics = PanelMetrics.new(aabb(v2(0, 0), v2(0, 0)), v2(0, 0))

    def self.reset
      @@panel_counter = 0
      @@panel_parent = 0
      @@button_counter = 0
      @@metrics = PanelMetrics.new(aabb(v2(0, 0), v2(0, 0)), v2(0, 0))
    end

    def self.parent
      @@panel_parent.unsafe_as(LibEngine::Panel)
    end

    def self.metrics
      @@metrics
    end

    def self.metrics=(x)
      @@metrics = x
    end

    def self.read_metrics
      @@metrics = PanelMetrics.read_from_engine
    end

    def self.parent=(x)
      @@panel_parent = x.to_i
    end

    def self.new_panel
      @@panel_counter += 1
      @@panel_counter.unsafe_as(LibEngine::Panel)
    end

    def self.new_button
      @@button_counter += 1
      @@button_counter.unsafe_as(Pointer(Void))
    end

    def self.box
      @@metrics.box
    end

    def self.cursor
      @@metrics.cursor
    end

    def self.button_state
      inside = aabb(v2(0, 0), v2(1, 1)).includes?(GUI.cursor)
      state = ButtonState::Normal
      if inside
        if Mouse.left.clicked?
          state = ButtonState::Clicked
        elsif Mouse.left.down?
          state = ButtonState::Pressed
        else
          state = ButtonState::Hover
        end
      end
      state
    end
  end

  def panel(x = 0, y = 0, width = 0, height = 0, halign = HAlign::None, valign = VAlign::None, fill : Color? = nil, border : Color? = nil, &)
    own_id = GUI.new_panel
    parent = GUI.parent
    metrics = GUI.metrics
    LibEngine.panel(own_id, parent, x, y, width, height, LibEngine::HAlign.new(halign.to_i), LibEngine::VAlign.new(valign.to_i))
    GUI.read_metrics

    rect(GUI.box, true, fill) if fill
    rect(GUI.box, false, border) if border
    GUI.parent = own_id
    x = yield
    GUI.parent = parent
    GUI.metrics = metrics
    x
  end

  def panel(*args, **args2)
    panel(*args, **args2) do
    end
  end

  def label(txt : String, font : Font, x = 0, y = 0, width = 0, height = 0, halign = HAlign::None, valign = VAlign::None, fill : Color? = nil, border : Color? = nil, text_halign = HAlign::None, text_valign = VAlign::None)
    panel(x, y, width, height, halign, valign, fill, border) do
      font.draw_text_boxed(txt, GUI.box, halign: text_halign, valign: text_valign)
    end
  end

  def edit(value : Int32, min : Int32, max : Int32, font : Font, x = 0, y = 0, width = 0, height = 0, halign = HAlign::None, valign = VAlign::None, fill : Color? = nil, border : Color? = nil, *, allow_scroll = false) : Int32?
    v = value
    panel(x, y, width, height, halign, valign, fill, border) do
      b = false
      size = GUI.box.size
      v = LibEngine.input_int(value, min, max, GUI.parent, 0, 0, size.x, size.y, LibEngine::HAlign::None, LibEngine::VAlign::None, font, pointerof(b), GUI.parent.unsafe_as(Pointer(Void)))
      v += Mouse.scroll.to_i if allow_scroll && GUI.button_state.hover?
    end
    v == value ? nil : v
  end

  enum ButtonState
    Normal
    Hover
    Pressed
    Clicked
  end

  DEFAULT_BTN_FONT = Font.new(FontResource.new(0), dont_create: true)

  def button(resource : ButtonResource, x = 0, y = 0, width = 0, height = 0, text : String? = nil, halign : HAlign = HAlign::None, valign : VAlign = VAlign::None, font : (Font | FontResource | Nil) = nil)
    # own_id = GUI.new_button
    LibEngine.button(resource.to_unsafe, GUI.parent, x, y, width, height, LibEngine::HAlign.new(halign.to_i), LibEngine::VAlign.new(valign.to_i), (text ? text.to_unsafe : Pointer(UInt8).null), font || DEFAULT_BTN_FONT, nil).unsafe_as(ButtonState)
  end

  def button(*args, **args2, &)
    metrics = GUI.metrics
    state = button(*args, **args2)
    GUI.read_metrics
    x = yield(state) unless state.normal?
    GUI.metrics = metrics
    x
  end

  def button_clicked(*args, **args2, &)
    metrics = GUI.metrics
    state = button(*args, **args2)
    GUI.read_metrics
    x = yield if state.clicked?
    GUI.metrics = metrics
    x
  end

  struct ButtonResource
    @data : Int32

    def initialize(@data)
    end

    def to_unsafe
      @data.unsafe_as(LibEngine::Button)
    end
  end
end
