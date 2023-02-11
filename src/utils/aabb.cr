record AABB, v0 : Vector2, size : Vector2 do
  def center
    v0 + size/2
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
