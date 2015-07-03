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
      return Move.new('STAY', false,'死んでます')
    end

    moves_to_consider = legal_moves(state, @id)
    chosen = moves_to_consider.max_by do |m|
      # パラメータ
      nsimulations = 20
      depth = 15

      scores = nsimulations.times.map do |simnum|
        commands = (0..3).map do |id|
          if id == @id
            [id, m]
          else
            [id, legal_moves(state, id).sample]
          end
        end.to_h
        s = state.transition(commands)
        depth.times do |turn|
          break unless s.find_player(@id)['isAlive']
          # STDERR.pp [simnum, turn]
          commands = (0..3).map do |id|
            [id, legal_moves(s, id).sample]
          end.to_h

          s.transition!(commands)
        end
        score(s, @id)
      end
      arithmetic_mean scores
    end
    chosen
  end

  private

  def arithmetic_mean(list)
    raise 'empty list' if list.empty?
    list.inject(:+).fdiv list.size
  end

  # GameState → [Move]
  def legal_moves(state, id)
    player = state.find_player(id)
    dirs = (DIR - ['STAY']).select { |d|
      x, y = player['pos'].values_at('x', 'y')
      xoff, yoff = GameState::DIR_OFFSETS[d]
      pos = {'x'=>x+xoff, 'y'=>y+yoff}
      !(state.wall?(pos) or state.block?(pos) or state.bomb?(pos))
    }
    dirs += ['STAY'] # staying is always possible
    dirs.flat_map do |d|
      if state.player_can_set_bomb(player)
        [true, false].map do |b|
          Move.new(d, b)
        end
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
