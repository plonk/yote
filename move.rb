class Move
  attr_reader :command, :bomb
  attr_accessor :comment

  def initialize(command, bomb, comment = nil)
    @command = command
    @bomb = bomb
    @comment = comment
  end

  def to_s
    "#{@command},#{@bomb}" + (@comment ? ",#@comment" : "")
  end
end
