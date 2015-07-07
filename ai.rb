require_relative 'move'
require 'pp'

class IO
  def pp(v)
    self.puts v.pretty_inspect
  end
end

def time
  beg = Time.now
  yield
  Time.now - beg
end

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

# ボムマンAIクラス
class BombmanAi
  attr_reader :name, :id

  DIR = %w[UP DOWN LEFT RIGHT STAY]

  def initialize(name, id)
    @name = name
    @id = id
  end

  # シミュレーションのパラメータ
  NSIMULATIONS = 10 # 一手につきシミュレーションを行う回数
  DEPTH = 15        # 何手先までシミュレーションを行うか

  # 手を決定する
  # GameState → Move
  def move(state)
    unless state.find_player(@id)['isAlive']
      return Move.new('STAY', false)
    end

    legal_moves(state, @id).max_by do |m|
      score_move(m, state)
    end
  end

  # (GameState, Integer) → [GameState]
  # depth 手先まで、全てのプレーヤーをランダム移動させ、
  # 状態の系列を返す
  def simulate(state, depth)
    series = []
    depth.times do
      series << state
      break unless state.find_player(@id)['isAlive']
      commands = (0..3).map do |id|
        [id, legal_moves(state, id).sample]
      end.to_h

      state = state.transition(commands)
    end
    series
  end

  # (GameState, Integer) → GameState
  # depth 手先まで、全てのプレーヤーをランダム移動させる
  # state を破壊的に変更し、state を返す
  def simulate!(state, depth)
    depth.times do
      break unless state.find_player(@id)['isAlive']
      commands = (0..3).map do |id|
        [id, legal_moves(state, id).sample]
      end.to_h

      state.transition!(commands)
    end
    state
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

      # series = simulate(first_step, DEPTH - 1)
      # result = series.last
      result = simulate!(first_step, DEPTH - 1)
      score(result, @id)
    end
    arithmetic_mean scores
  end

  # [Numeric] → Float
  def arithmetic_mean(list)
    raise 'empty list' if list.empty?
    list.inject(:+).fdiv list.size
  end

  FOUR_CORNERS = [[1,1], [13,1], [13,13], [1,13]]
  # (GameState, Integer) → [Move]
  def legal_moves(state, id)
    player = state.find_player(id)
    dirs = (DIR - ['STAY']).select { |d|
      vec = GameState::DIR_OFFSETS[d]
      state.enterable?(player['pos'].addvec(vec))
    } + ['STAY'] # staying is always possible
    pos = player['pos'].to_coords
    can_set_bomb = state.player_can_set_bomb(player)
    dirs.flat_map do |d|
      if can_set_bomb && !FOUR_CORNERS.include?(pos)
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
    x += ([*0..3] - [id]).count { |i| !state.find_player(i)['isAlive'] } * 50

    # 自分のステータスが高い方が良い
    x += me['power'] * 10 + me['setBombLimit'] * 5

    return x
  end

end
