record GLSLItem, id : Int32, item : String, typ : String, count : Int32 do
  def line
    if @count > 1
      # uniform_array screen_size, 80, Vec2, 0
      "_array #{@item}, #{@count}, #{@typ}, #{id}"
    else
      # uniform screen_size, Vec2, 0
      " #{@item}, #{@typ}, #{id}"
    end
  end
end

record Shader, name : String, filename : String, uniforms : Array(GLSLItem), attributes : Array(GLSLItem) do
  def initialize(@name, @filename)
    @uniforms = [] of GLSLItem
    @attributes = [] of GLSLItem
  end

  def print(processor)
    processor.print ""
    processor.print "class #{@name} < Shader"
    @uniforms.each do |item|
      processor.print "  uniform#{item.line}"
    end
    @attributes.each do |item|
      processor.print "  attribute#{item.line}"
    end
    processor.print "end"
  end
end

class Processor
  @shaders = [] of Shader
  @all_shaders = Shader.new("ShaderAllShaders", "")
  @cur_uniform_id = 0
  @cur_attribute_id = 0
  @uniform_items = {} of String => GLSLItem
  @attribute_items = {} of String => GLSLItem

  def fine_name(s)
    return s if s == "RES"
    s = s.chars.select { |c| c.ascii_alphanumeric? || c == '_' }.join
    s = "id_" + s if s == "" || s[0].ascii_number?
    s.capitalize
  end

  USED_NAMES = Set(String).new
  RES_IDS    = Hash(String, Int32).new(0)
  @indent = 0
  @need_space = false

  def unique_name(s)
    if USED_NAMES.includes? s
      n = 1
      while USED_NAMES.includes? s + "_" + n.to_s
        n += 1
      end
      s = s + "_" + n.to_s
    end
    USED_NAMES << s
    s
  end

  GRAPH_EXTS       = ["bmp", "dds", "jpg", "png", "tga", "psd"]
  SOUND_EXTS       = ["wav", "ogg", "flac"]
  FONT_EXTS        = ["ttf", "otf", "fnt"]
  SHADER_PARTS_EXT = ["vs", "fs", "gs", "tcs", "tes", "hs"]
  SHADER_EXT       = "shader"

  def print_res(res, item, is_shader = false)
    item = unique_name(fine_name(item))
    print "#{item} = #{res}#{is_shader ? item.capitalize : ""}.new(#{RES_IDS[res]})"
    RES_IDS[res] = RES_IDS[res] + 1
  end

  def detect_dir(adir, andprint)
    if m = /(.*)_font$/.match(adir)
      print_res "FontResource", m[1] if andprint
      return true
    end
    if m = /(.*)_button$/.match(adir)
      print_res "ButtonResource", m[1] if andprint
      return true
    end
    false
  end

  def detect_file(afile) : Bool?
    m = /(.*)\.([^\.]*)$/.match(afile)
    raise afile unless m
    name, ext = m[1], m[2]
    ext = ext.downcase
    if SHADER_PARTS_EXT.includes? ext
      # ignored
      return
    end
    if GRAPH_EXTS.includes? ext
      if m = /(.*)_tiled_([[:digit:]]*)x([[:digit:]]*)$/.match(name)
        print_res "TileMap", m[1]
        return
      end

      print_res "Sprite", name
      return
    end
    if SOUND_EXTS.includes? ext
      print_res "Sound", name
      return
    end
    if FONT_EXTS.includes? ext
      print_res "FontResource", name
      return
    end
    if ext == SHADER_EXT
      print_res "Shader", name, is_shader: true
      return true
    end
    print_res "RawResource", name
    return nil
  end

  def print(s)
    if @need_space
      @out_file.puts ""
      @need_space = false
    end
    @out_file.puts "#{" "*@indent}#{s}"
  end

  def process_dir(short, adir)
    print "module #{fine_name(short)}"
    @indent += 2
    Dir.each(adir) do |item|
      next if item == "." || item == ".."
      process_dir(item, adir + "/" + item) if Dir.exists?(adir + "/" + item) && !detect_dir(item, false)
    end
    Dir.each(adir) do |item|
      next if item == "." || item == ".."
      if Dir.exists?(adir + "/" + item)
        detect_dir(item, true)
      else
        x = detect_file(item)
        if x
          @shaders << Shader.new("Shader" + item.gsub(".shader", "").capitalize, adir + "/" + item)
        end
      end
    end
    @indent -= 2
    @need_space = false
    print "end"
    @need_space = true
  end

  @path : String
  @out_file : File

  def initialize(@path, out_filename)
    @out_file = File.open(out_filename, "w+")
  end

  def print_shader(shader)
    print ""
    print "class #{shader.name} < Shader"
    shader.uniforms.each do |item|
      print "  uniform#{item.line}"
    end
    shader.attributes.each do |item|
      print "  attribute#{item.line}"
    end
    print "end"
  end

  def fill_default_shader
    @uniform_items["screen_size"] = GLSLItem.new(0, "screen_size", "vec2", 1)
    @uniform_items["tex"] = GLSLItem.new(1, "tex", "sampler2D", 1)
    @cur_uniform_id = 2
    @attribute_items["color"] = GLSLItem.new(0, "color", "vec4", 1)
    @attribute_items["pos"] = GLSLItem.new(1, "pos", "vec3", 1)
    @attribute_items["texpos"] = GLSLItem.new(2, "texpos", "vec3", 1)
    @cur_attribute_id = 3
  end

  def load_shader(shader)
    File.each_line(shader.filename) do |str|
      str = str.strip
      if m = /uniform:( *)(.*)\[(.*)\]:( *)(.*)/.match(str)
        name, count, typ = m[2], m[3], m[5]
        # id : Int32, item : String, typ : String, count : Int32
        item = @uniform_items[name]?
        unless item
          id = @cur_uniform_id
          @cur_uniform_id += 1
          item = GLSLItem.new(id, name, typ, count.to_i)
          @uniform_items[name] = item
        end
        shader.uniforms << item
      elsif m = /uniform:( *)(.*):( *)(.*)/.match(str)
        name, typ = m[2], m[4]
        item = @uniform_items[name]?
        unless item
          id = @cur_uniform_id
          @cur_uniform_id += 1
          item = GLSLItem.new(id, name, typ, 1)
          @uniform_items[name] = item
        end
        shader.uniforms << item
      elsif m = /attribute:( *)(.*):( *)(.*)/.match(str)
        name, typ = m[2], m[4]
        item = @attribute_items[name]?
        unless item
          id = @cur_attribute_id
          @cur_attribute_id += 1
          item = GLSLItem.new(id, name, typ, 1)
          @attribute_items[name] = item
        end
        shader.attributes << item
      end
    end
  end

  def go
    RES_IDS["Shader"] = 1
    print "include Engine

THE_SCREEN = Sprite.new(-1)
NO_MUSIC = Sound.new(-1)
DEFAULT_SHADER = DefaultShader.new(0)
ALL_SHADERS = ShaderAllShaders.new(-1)
    "
    process_dir "RES", @path
    fill_default_shader
    @shaders.each do |shader|
      load_shader(shader)
    end
    @shaders.each &.print(self)
    @all_shaders.uniforms.concat @uniform_items.values
    @all_shaders.attributes.concat @attribute_items.values
    @all_shaders.print(self)
    @out_file.close
  end
end

Processor.new(ARGV.size > 0 ? ARGV[0] : "./resources", ARGV.size > 1 ? ARGV[1] : "./src/resources.cr").go
