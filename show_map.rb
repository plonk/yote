require_relative 'game_state'

def show_map(game_state)
  w = h = 15
  map = Array.new(h) { |y| Array.new(w) { |x| '　' } }

  pos   = -> xs { xs.map { |x| x['pos'].values_at('x', 'y') } }
  id    = -> x { x }
  const = -> x { proc { x } }
  key   = -> k { -> coll { coll[k] } }

  [[:blocks,  id,  const.('□')],
   [:bombs,   pos, const.('●')],
   [:items,   pos, key.('name')],
   [:fires,   id,  const.('火')],
   [:walls,   id,  const.('■')],
   [:players, pos,   key.('ch')]].each do |prop, trans, rep|
    objects = game_state.send(prop)
    points = trans.(objects)
    objects.zip(points).each do |obj, (x, y)|
      map[y][x] = rep.(obj)
    end
  end

  return map.map { |row| row.join + "\n" }.join
end
