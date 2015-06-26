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
    unless state.find_player(@id)['isAlive']
      return Move.new('STAY','FALSE','死んでます')
    end

    all_moves = legal_moves(state)
    moves_to_consider = legal_moves(state)

    chosen = moves_to_consider.max_by do |m|
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

          s.transition!(commands)
        end
        score(s, @id)
      end
      arithmetic_mean scores
    end

    chosen.comment = 'ほげ'
    chosen
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
