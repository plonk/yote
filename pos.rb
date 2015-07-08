module PosMethods
  def to_coords
    values_at('x', 'y')
  end

  def addvec(unit_vector)
    fail ArgumentError unless unit_vector.is_a? Array and unit_vector.size == 2
    xoff, yoff = unit_vector
    res = dup()
    res['x'] += xoff
    res['y'] += yoff
    res
  end
end

class Hash
  include PosMethods
end

class Array
  def to_pos
    { 'x' => first, 'y' => self[1] }
  end
end
