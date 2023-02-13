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

struct Vector2
  def inside?(aabb)
    (aabb.v0.x..aabb.v0.x + aabb.size.x).includes?(self.x) && (aabb.v0.y..aabb.v0.y + aabb.size.y).includes?(self.y)
  end
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
