record Vector2, x : Float64, y : Float64 do
  def length
    Math.hypot(x, y)
  end

  def abs
    length
  end

  def sqrlength
    x*x + y*y
  end

  def angle
    Math.atan2(y, x)
  end

  def self.from_angle(angle, length)
    self.new(Math.cos(angle)*length, Math.sin(angle)*length)
  end

  def self.zero
    self.new(0, 0)
  end

  def close(other, eps = 1.0)
    return (x - other.x).abs < eps && (y - other.y).abs < eps
  end

  def inspect(io)
    io << "Vector2(x=" << @x << ", y=" << @y << ", l=" << length << ", a=" << (angle/Math::PI*180) << ")"
  end

  def -(other)
    return Vector2.new(@x - other.x, @y - other.y)
  end

  def -
    return Vector2.new(-@x, -@y)
  end

  def +(other)
    return Vector2.new(@x + other.x, @y + other.y)
  end

  def *(scale : Number)
    return Vector2.new(@x*scale, @y*scale)
  end

  def *(scale : Vector2)
    return Vector2.new(@x*scale.x, @y*scale.y)
  end

  def /(scale)
    return Vector2.new(@x/scale, @y/scale)
  end

  def dot(other)
    return @x * other.x + @y * other.y
  end

  def cross(other)
    return @x * other.y - @y * other.x
  end

  def normalize
    return self / self.length
  end

  def rotate(angle)
    c = Math.cos(angle)
    s = Math.sin(angle)
    Vector2.new(c*x - s*y, s*x + c*y)
  end

  def inside?(aabb)
    (aabb.left..aabb.right).includes?(self.x) && (aabb.top..aabb.bottom).includes?(self.y)
  end
end

record AABB, v0 : Vector2, size : Vector2 do
  def center
    v0 + size/2
  end

  def topright
    v0 + v2(size.x, 0)
  end

  def bottomleft
    v0 + v2(0, size.y)
  end

  def topleft
    v0
  end

  def bottomright
    v0 + size
  end

  def left
    v0.x
  end

  def right
    v0.x + size.x
  end

  def top
    v0.y
  end

  def bottom
    v0.y + size.y
  end

  def width
    size.x
  end

  def height
    size.y
  end
end

struct Number
  def degrees
    Math::PI * self / 180
  end

  def *(v : Vector2)
    v*self
  end
end

def v2(x, y)
  Vector2.new(x, y)
end

def aabb(v0, size)
  AABB.new(v0, size)
end

def aabb(x0, y0, *, w, h)
  AABB.new(v2(x0, y0), v2(w, h))
end

def aabb(*, x0, y0, x1, y1)
  AABB.new(v2(x0, y0), v2(x1 - x0, y1 - y0))
end

def split_text(s, font, width)
  results = [] of String
  cur = ""
  s.split(' ').each do |part|
    added = "#{cur} #{part}"
    x, y = font.measure(added)
    if x > width
      results << cur.strip
      cur = part
    else
      cur = added
    end
  end
  results << cur.strip if cur != ""
  results
end
