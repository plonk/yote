require 'pp'

class IO
  def pp(v)
    self.puts v.pretty_inspect
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

  # 手を決定する
  # GameState → Move
  def move(state)
    unless state.player_by_id(@id)['isAlive']
      return Move.new('STAY','FALSE','死んでます')
    end

    all_moves = legal_moves(state)
    moves_to_consider = legal_moves(state)

    moves_to_consider.max_by do |m|
      # パラメータ
      nsimulations = 10
      length = 15

      scores = nsimulations.times.map do |simnum|
        commands = (0..3).map do |id|
          if id == @id
            [id, m]
          else
            [id, all_moves.sample]
          end
        end.to_h
        s = state.transition(commands)
        length.times do |turn|
          # STDERR.pp [simnum, turn]
          commands = (0..3).map do |id|
            [id, all_moves.sample]
          end.to_h

          s = s.transition(commands)
        end
        score(s, @id)
      end
      arithmetic_mean scores
    end
  end

  private

  def arithmetic_mean(list)
    raise 'empty list' if list.empty?
    list.inject(:+).fdiv list.size
  end

  # GameState → [Move]
  def legal_moves(state)
    DIR.flat_map do |d|
      [true, false].map do |b|
        Move.new(d, b)
      end
    end
  end

  # 評価関数
  # ゲーム状態 state はプレーヤー id にとってどれほど有利であるか
  def score(state, id)
    x = 0
    me = state.player_by_id(id)

    # 自分が死んでいるのは悪い
    x += -100 unless me['isAlive']

    # 自分以外の敵が少ない方が良い
    x += ([*0..3] - [id]).count { |i| !state.player_by_id(i)['isAlive'] } * 10

    # 自分のステータスが高い方が良い
    x += me['power'] + me['setBombLimit']

    # 壁が降ってくる場所は良くない
    if DANGER_ZONE.include? me['pos'].values_at('x', 'y')
      x += -50
    end

    return x
  end

  DANGER_ZONE = [[1, 1], [2, 1], [3, 1], [4, 1], [5, 1], [6, 1], [7, 1],
   [8, 1], [9, 1], [10, 1], [11, 1], [12, 1], [13, 1], [13, 2],
   [13, 3], [13, 4], [13, 5], [13, 6], [13, 7], [13, 8], [13, 9],
   [13, 10], [13, 11], [13, 12], [13, 13], [12, 13], [11, 13],
   [10, 13], [9, 13], [8, 13], [7, 13], [6, 13], [5, 13], [4, 13],
   [3, 13], [2, 13], [1, 13], [1, 12], [1, 11], [1, 10], [1, 9],
   [1, 8], [1, 7], [1, 6], [1, 5], [1, 4], [1, 3], [1, 2], [2, 2],
   [3, 2], [4, 2], [5, 2], [6, 2], [7, 2], [8, 2], [9, 2], [10, 2],
   [11, 2], [12, 2], [12, 3], [12, 4], [12, 5], [12, 6], [12, 7],
   [12, 8], [12, 9], [12, 10], [12, 11], [12, 12], [11, 12], [10, 12],
   [9, 12], [8, 12], [7, 12], [6, 12], [5, 12], [4, 12], [3, 12],
   [2, 12], [2, 11], [2, 10], [2, 9], [2, 8], [2, 7], [2, 6], [2, 5],
   [2, 4], [2, 3], [3, 3], [4, 3], [5, 3], [6, 3], [7, 3], [8, 3],
   [9, 3], [10, 3], [11, 3], [11, 4], [11, 5], [11, 6], [11, 7],
   [11, 8], [11, 9], [11, 10], [11, 11], [10, 11], [9, 11], [8, 11],
   [7, 11], [6, 11], [5, 11], [4, 11], [3, 11], [3, 10], [3, 9], 
   [3, 8], [3, 7], [3, 6], [3, 5], [3, 4], [4, 4], [5, 4], [6, 4],
   [7, 4], [8, 4], [9, 4], [10, 4], [10, 5], [10, 6], [10, 7],
   [10, 8], [10, 9], [10, 10], [9, 10], [8, 10], [7, 10],
   [6, 10], [5, 10], [4, 10], [4, 9], [4, 8], [4, 7], [4, 6],
   [4, 5]]
end
