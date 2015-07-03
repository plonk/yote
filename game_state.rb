require 'json'

class GameState
  attr_reader :struct

  def initialize(struct)
    @struct = struct
  end

  def initialize_copy(orig)
    @struct = JSON.parse(orig.struct.to_json)
  end

  # {Integer => Move} → GameState
  def transition(id_to_move)
    state = self.clone
    state.transition!(id_to_move)
    return state
  end

  def find_player(id)
    players.find { |player| player['id'] == id }
  end

  def block?(pos)
    blocks.include? pos.values_at('x', 'y')
  end

  def item?(pos)
    items.map { |i| i['pos'] }.include? pos
  end

  def wall?(pos)
    walls.include? pos.values_at('x', 'y')
  end

  def explode_bomb(bomb)
    fire_column = -> pos, dirvec, power {
      if power == 0
        []
      else
        xoff, yoff = dirvec
        next_pos = {"x"=>pos['x'] + xoff, "y"=>pos['y'] + yoff}
        if wall?(next_pos)
          []
        elsif block? next_pos or item? next_pos
          [pos_to_a(next_pos)]
        else
          [pos_to_a(next_pos)] + fire_column.(next_pos, dirvec, power - 1)
        end
      end
    }

    %w(UP DOWN LEFT RIGHT).flat_map { |d|
      fire_column.(bomb['pos'], DIR_OFFSETS[d], bomb['power'])
    } + [pos_to_a(bomb['pos'])]
  end

  # [{'pos'=>(Integer,Integer), 'power'=>Integer, 'timer'=>Integer}] → [(Integer,Integer)]
  def explode_bombs(bs)
    bs.flat_map { |b| explode_bomb(b) }
  end

  def item_effect!(item, player)
    case item['name']
    when '力'
      player['power'] += 1
    when '弾'
      player['setBombLimit'] += 1
    else
      raise "unknown item #{item.name}"
    end
  end

  # {Integer => Move}
  def transition!(id_to_move)
    id_to_move.each_pair do |id, move|
      eval_action!(find_player(id), move)
    end

    self.turn += 1

    # サドンデス時の落下する壁
    if turn >= 360 and turn - 360 < FALLING_WALLS.size
      pt = FALLING_WALLS[turn-360]
      walls << pt
      blocks.delete(pt)
      items.delete_if { |item| item['pos'].values_at('x','y') == pt }
      bombs.delete_if { |bomb| bomb['pos'].values_at('x','y') == pt }
      players.each do |player|
        if pos_to_a(player['pos']) == pt
          player['isAlive'] = false
          player['ch'] = '墓'
        end
      end
    end

    bombs.each do |bomb|
      bomb['timer'] -= 1
    end

    players.each do |player|
      items.each do |item|
        if item['pos'] == player['pos']
          item_effect!(item, player)
          self.items -= [item]
        end
      end
    end

    bombs_to_explode = bombs.select { |b| b['timer'] <= 0 }
    fires = []
    until bombs_to_explode.size == 0
      # setBombCountの追跡はできない
      fires += explode_bombs(bombs_to_explode)
      self.bombs -= bombs_to_explode
      bombs_to_explode = bombs.select { |b| fires.include? pos_to_a(b['pos']) }
    end
    self.fires = fires

    items.delete_if do |item|
      fires.include? pos_to_a(item['pos'])
    end

    blocks.delete_if do |block|
      # アイテムが出る処理は書けない
      fires.include? block
    end

    players.each do |player|
      pt = pos_to_a player['pos']
      if fires.include? pt
        player['isAlive'] = false
        player['ch'] = '墓'
      end
    end
  end

  def pos_to_a(pos)
    [pos['x'], pos['y']]
  end

  def player_can_set_bomb(player)
    raise 'player' unless player.is_a? Hash
    player['isAlive'] && !bomb?(player['pos']) && player['setBombLimit'] > player['setBombCount']
  end

  def bomb?(pos)
    bombs.any? { |b| b['pos'] == pos }
  end

  def player_set_bomb!(player)
    raise unless player_can_set_bomb(player)
    # player['setBombCount'] += 1
    player['totalSetBombCount'] += 1
    self.bombs += [{"pos" => player['pos'],
                "timer" => 10,
                "power" => player['power']}]
  end

  DIR_OFFSETS = {
    'UP'    => [ 0, -1],
    'DOWN'  => [ 0,  1],
    'LEFT'  => [-1,  0],
    'RIGHT' => [ 1,  0],
    'STAY'  => [ 0,  0]
  }

  def eval_action!(player, move)
    if move.bomb && player_can_set_bomb(player)
      player_set_bomb!(player)
    end

    dx, dy = DIR_OFFSETS[move.command]
    next_pos = {
      "x" => player['pos']['x'] + dx,
      "y" => player['pos']['y'] + dy }
    next_pt = pos_to_a(next_pos)

    if player['isAlive'] &&
        !bombs.map{|b| b['pos']}.include?(next_pos) &&
        !blocks.include?(next_pt) &&
        !walls.include?(next_pt)
      player['pos'] = next_pos
    end
  end

  %w[turn walls blocks players bombs items fires].each do |acc|
    define_method(acc) do
      @struct[acc]
    end

    define_method("#{acc}=") do |x|
      @struct[acc] = x
    end
  end

  spiral = proc do |left, right, top, bottom|
    if left == 5
      []
    else
      left      .upto(right)  .map { |x| [x, top]    } +
      (top+1)   .upto(bottom) .map { |y| [right, y]  } +
      (right-1) .downto(left) .map { |x| [x, bottom] } +
      (bottom-1).downto(top+1).map { |y| [left, y]   } +
      spiral.(left+1, right-1, top+1, bottom-1)
    end
  end
  FALLING_WALLS = spiral.(1, 13, 1, 13)

  def finished?
    players.count { |player| player['isAlive'] } <= 1
  end

  def winner
    return nil unless finished?
    players.find { |player| player['isAlive'] }
  end

end
