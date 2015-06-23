#!/usr/bin/env ruby --encoding=UTF-8:UTF-8
# coding: utf-8

require 'json'
require_relative 'game_state'
require_relative 'move'

class BombmanAi
  attr_reader :name, :id

  DIR = %w[UP DOWN LEFT RIGHT STAY]

  def initialize(name)
    @name = name
  end

  def handshake
    puts @name
    @id = readline.to_i
  end

  # () → GameState
  def recv_game_state
    json_str = gets
    GameState.new JSON.parse(json_str)
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

  def run
    handshake

    loop do
      state = recv_game_state
      moves = legal_moves(state)
      move = moves.max_by { |m| score_move(state, m) }
      puts move
    end
  end
end

STDOUT.sync = true
BombmanAi.new("予定地").run
