#!/usr/bin/env ruby --encoding=UTF-8:UTF-8
# coding: utf-8

require 'json'
require_relative 'game_state'
require_relative 'move'
require_relative 'ai'

class BombmanClient
  attr_reader :name, :id

  def initialize(in_io, out_io, name)
    @in, @out, @name = in_io, out_io, name
    @ai = nil
  end

  def run
    synchronized_io do
      interact
    end
  end

  private

  def interact
    @id = handshake(@name)
    @ai = BombmanAi.new(@name, @id)

    while state = recv_game_state
      break unless state
      move = @ai.move state
      @out.puts move
    end
  end

  def handshake(name)
    @out.puts name
    @in.readline.to_i
  end

  # () → GameState or nil
  def recv_game_state
    json_str = @in.gets
    if json_str
      GameState.new JSON.parse(json_str)
    else
      nil
    end
  end

  def synchronized_io
    init_sync_state = @out.sync
    @out.sync = true
    yield
  ensure
    @out.sync = init_sync_state
  end
end

BombmanClient.new(STDIN, STDOUT, "予定地").run
