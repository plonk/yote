require_relative 'move'
require_relative 'pos'

# ボムマンAIクラス
class BombmanAi
  # シミュレーションのパラメータ
  NSIMULATIONS = 5  # 一手につきシミュレーションを行う回数
  DEPTH = 15        # 何手先までシミュレーションを行うか

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
      return Move.new('STAY', false)
    end

    time_start = Time.now
    loop do
      moves = legal_moves(state, @id)
      scores = moves.map do |m|
        score = score_move(m, state)
        # STDERR.puts "#{m.to_s}: #{score}"
        score
      end
      # 生き残る未来が見えない場合は、450ms で探索を打ち切って
      # 爆弾を置かないランダムな手を選択する。
      if scores[0] < -50 && scores.all? { |s| s == scores[0] }
        if Time.now - time_start < 0.45
          next
        else
          return moves.find { |m| m.bomb == false }
        end
      end
      # 他より良い手が見付かればそれを選択する。
      return moves.max_by.with_index { |move, i| scores[i] }
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
      score(result, @id).tap do |s|
        # STDERR.puts s.inspect
      end
    end
    arithmetic_mean scores
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
      state.enterable?(player['pos'].addvec(vec))
    } + ['STAY'] # staying is always possible
    can_set_bomb = state.player_can_set_bomb(player)
    dirs.flat_map do |d|
      if can_set_bomb
        [Move.new(d, true), Move.new(d, false)]
      else
        [Move.new(d, false)]
      end
    end
  end

  # 評価関数
  # ゲーム状態 state はプレーヤー id にとってどれほど有利であるか
  def score(state, id)
    state.find_player(id)['isAlive'] ? 0 : -100
  end

end
