# ボムマンAIクラス
class BombmanAi
  attr_reader :name, :id

  DIR = %w[UP DOWN LEFT RIGHT STAY]

  def initialize(name, id)
    @name = name
    @id = id
  end

  # GameState → [Move]
  def legal_moves(state)
    DIR.flat_map do |d|
      [true, false].map do |b|
        Move.new(d, b)
      end
    end
  end

  # (GameState, Move) → Integer
  def score_move(state, move)
    ms = legal_moves(state)
    others = ([0, 1, 2, 3] - [self.id]).map { |x| [x, ms.sample] }.to_h
    return score(state.transition({self.id => move}.merge(others)),
                 self.id)
  end

  # 手を決定する
  # GameState → Move
  def move(state)
    moves = legal_moves(state)
    moves.max_by { |m| score_move(state, m) }
  end

  # 評価関数
  def score(state, id)
    x = 0
    me = state.player_by_id(id)

    # 自分が死んでいるのは悪い
    x += -100 unless me['isAlive']

    # 自分以外の敵が少ない方が良い
    x += ([*0..3] - [id]).count { |i| !state.player_by_id(i)['isAlive'] } * 10

    # 自分のステータスが高い方が良い
    x += me['power'] + me['setBombLimit']
    x
  end

end
