require 'json'
require 'set'

class GameState
  attr_reader :turn, :walls, :blocks, :players, :bombs, :items, :fires

  def initialize(struct)
    @turn = struct['turn']
    @walls = Set.new(struct['walls'])
    @blocks = Set.new(struct['blocks'])
    @players = struct['players']
    @bombs = struct['bombs']
    @items = struct['items']
    @fires = Set.new(struct['fires'])
  end

  def initialize_copy(orig)
    @turn = orig.turn
    @walls = orig.walls.dup
    @blocks = orig.blocks.dup
    @players = Marshal.load Marshal.dump orig.players
    @bombs = Marshal.load Marshal.dump orig.bombs
    @items = Marshal.load Marshal.dump orig.items
    @fires = orig.fires.dup
  end

  def to_json
    {
      "turn" => @turn,
      "walls" => @walls.to_a,
      "blocks" => @blocks.to_a,
      "players" => @players,
      "bombs" => @bombs,
      "items" => @items,
      "fires" => @fires.to_a
    }.to_json
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
    blocks.include? pos.to_coords
  end

  def item?(pos)
    items.any? { |item| item['pos'] == pos }
  end

  def wall?(pos)
    walls.include? pos.to_coords
  end

  def explode_bomb(bomb)
    fire_column = -> pos, dirvec, power {
      if power == 0
        []
      else
        next_pos = pos.addvec(dirvec)
        if wall?(next_pos)
          []
        elsif block? next_pos or item? next_pos
          [next_pos.to_coords]
        else
          [next_pos.to_coords] + fire_column.(next_pos, dirvec, power - 1)
        end
      end
    }

    %w(UP DOWN LEFT RIGHT).flat_map { |d|
      fire_column.(bomb['pos'], DIR_OFFSETS[d], bomb['power'])
    } + [bomb['pos'].to_coords]
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

  # {Integer => Move} → GameState
  def transition!(id_to_move)
    (0..3).each do |id|
      eval_put_bomb_action!(find_player(id), id_to_move[id])
    end

    (0..3).each do |id|
      eval_move_action!(find_player(id), id_to_move[id])
    end

    @turn += 1

    # サドンデス時の落下する壁
    if turn >= 360 and turn - 360 < FALLING_WALLS.size
      pt = FALLING_WALLS[turn-360]
      @walls += [pt]
      @blocks.delete(pt)
      @items.delete_if { |item| item['pos'].to_coords == pt }
      @bombs.delete_if { |bomb| bomb['pos'].to_coords == pt }
    end

    @bombs.each do |bomb|
      bomb['timer'] -= 1
    end

    @players.each do |player|
      @items.each do |item|
        if item['pos'] == player['pos']
          item_effect!(item, player)
          @items -= [item]
        end
      end
    end

    bombs_to_explode = @bombs.select { |b| b['timer'] <= 0 }
    new_fires = Set.new
    until bombs_to_explode.size == 0
      # setBombCountの追跡はできない
      new_fires += explode_bombs(bombs_to_explode)
      @bombs -= bombs_to_explode
      bombs_to_explode = @bombs.select { |b| new_fires.include? b['pos'].to_coords }
    end
    @fires = new_fires

    @items.delete_if do |item|
      @fires.include? item['pos'].to_coords
    end

    # ブロックは 90 個。アイテムは力と弾が10個ずつ出る
    @blocks.delete_if do |coords|
      being_destroyed = @fires.include?(coords)
      if being_destroyed
        if rand < 20.0/90 # アイテムが出る確率
          @items += [{ 'pos' => coords.to_pos,
                       'name' => ['力', '弾'].sample }]
        end
      end
      being_destroyed
    end

    @players.each do |player|
      coords = player['pos'].to_coords
      if @fires.include?(coords) or @walls.include?(coords)
        player['isAlive'] = false
        player['ch'] = '墓'
      end
    end

    self
  end

  def player_can_set_bomb(player)
    raise 'player' unless player.is_a? Hash
    player['isAlive'] && !bomb?(player['pos']) && player['setBombLimit'] > player['setBombCount']
  end

  def bomb?(pos)
    bombs.any? { |b| b['pos'] == pos }
  end

  def player_set_bomb!(player)
    # raise unless player_can_set_bomb(player)
    player['setBombCount'] += 1
    player['totalSetBombCount'] += 1
    @bombs += [{"pos" => player['pos'],
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

  def eval_put_bomb_action!(player, move)
    if move.bomb && player_can_set_bomb(player)
      player_set_bomb!(player)
    end
  end

  def eval_move_action!(player, move)
    next_pos = player['pos'].addvec DIR_OFFSETS[move.command]

    if player['isAlive'] && enterable?(next_pos)
      player['pos'] = next_pos
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

  # プレーヤーが隣接するセルからこのセルに移動することを阻む物がない
  def enterable?(pos)
    !(wall?(pos) or block?(pos) or bomb?(pos))
  end

end
