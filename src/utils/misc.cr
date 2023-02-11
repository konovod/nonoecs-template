class MeasureGC
  getter value = 0
  @cur_value = 0u64

  def initialize
    @time = Time.utc
    @cur_value = GC.stats.total_bytes.to_u64
    @value = 0
  end

  def value
    update
    @value
  end

  private def update
    now = Time.utc
    if now - @time > 1.seconds
      n = GC.stats.total_bytes.to_u64
      @value = (n - @cur_value).to_i
      @cur_value = n
      @time = now
    end
  end
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

struct Number
  def degrees
    Math::PI * self / 180
  end
end
