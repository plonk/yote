require 'pp'

class IO
  def pp(v)
    self.puts v.pretty_inspect
  end
end

module PosMethods
  def to_coords
    values_at('x', 'y')
  end

  def addvec(unit_vector)
    fail ArgumentError unless unit_vector.is_a? Array and unit_vector.size == 2
    xoff, yoff = unit_vector
    res = dup()
    res.x += xoff
    res.y += yoff
    res
  end
end

class Hash
  include PosMethods

  def method_missing(name, *args, &block)
    if name.to_s =~ /(.*)=\z/
      str = $1
      if has_key?(str)
        self[str] = args.first
      else
        fail "key #{str} not found "
      end
    else
      str = name.to_s
      if has_key?(str)
        return self[str]
      else
        fail "key #{str} not found "
      end
    end
  end
end

# ボムマンAIクラス
class BombmanAi
  attr_reader :name, :id

  DIR = %w[UP DOWN LEFT RIGHT STAY]

  def initialize(name, id)
    @name = name
    @id = id
  end

  # シミュレーションのパラメータ
  NSIMULATIONS = 20 # 一手につきシミュレーションを行う回数
  DEPTH = 15        # 何手先までシミュレーションを行うか

  # 手を決定する
  # GameState → Move
  def move(state)
    unless state.find_player(@id)['isAlive']
      return Move.new('STAY', false, '死んでます')
    end

    legal_moves(state, @id).max_by do |m|
      score_move(m, state)
    end
  end

  private

  # Move → Float
  # move: 手
  # state: 手を打つ直前の状態
  def score_move(move, state)
    scores = NSIMULATIONS.times.map do
      # 一手目
      commands = (0..3).map do |id|
        if id == @id
          [id, move]
        else
          [id, legal_moves(state, id).sample]
        end
      end.to_h
      first_step = state.transition(commands)

      result = simulate(first_step, DEPTH - 1)
      score(result, @id)
    end
    arithmetic_mean scores
  end

  # (GameState, Integer) → GameState
  def simulate(state, depth)
    depth.times do |turn|
      break unless state.find_player(@id)['isAlive']
      commands = (0..3).map do |id|
        [id, legal_moves(state, id).sample]
      end.to_h

      state = state.transition(commands)
    end
    state
  end

  # [Numeric] → Float
  def arithmetic_mean(list)
    raise 'empty list' if list.empty?
    list.inject(:+).fdiv list.size
  end

  # (GameState, Integer) → [Move]
  def legal_moves(state, id)
    player = state.find_player(id)
    dirs = (DIR - ['STAY']).select { |d|
      vec = GameState::DIR_OFFSETS[d]
      state.enterable?(player.pos.addvec(vec))
    } + ['STAY'] # staying is always possible
    dirs.flat_map do |d|
      if state.player_can_set_bomb(player)
        [Move.new(d, true), Move.new(d, false)]
      else
        [Move.new(d, false)]
      end
    end
  end

  # 評価関数
  # ゲーム状態 state はプレーヤー id にとってどれほど有利であるか
  def score(state, id)
    x = 0
    me = state.find_player(id)

    # 自分が死んでいるのは悪い
    x += -100 unless me['isAlive']

    # 自分以外の敵が少ない方が良い
    x += ([*0..3] - [id]).count { |i| !state.find_player(i)['isAlive'] } * 10

    # 自分のステータスが高い方が良い
    # x += me['power'] + me['setBombLimit']

    return x
  end

end
