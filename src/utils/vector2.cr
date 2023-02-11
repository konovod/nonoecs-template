require "yaml"

record Vector2, x : Float64, y : Float64 do
  include YAML::Serializable

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

  def /(scale)
    return Vector2.new(@x/scale, @y/scale)
  end

  def //(other)
    if @x.abs < @y.abs
      return @x / other.x
    else
      return @y / other.y
    end
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
end

struct Number
  def *(v : Vector2)
    v*self
  end
end

def v2(x, y)
  Vector2.new(x, y)
end
