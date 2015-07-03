class Move
  attr_reader :command, :bomb
  attr_accessor :comment

  def initialize(command, bomb, comment = nil)
    raise 'bomb' unless [true, false].include?(bomb)
    @command = command
    @bomb = bomb
    @comment = comment
  end

  def to_s
    "#{@command},#{@bomb.to_s.upcase}" + (@comment ? ",#@comment" : "")
  end
end
