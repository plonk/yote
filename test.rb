require_relative 'game_state'
require_relative 'show_map'
require 'json'

init_state = JSON.parse '{"turn":0,"walls":[[0,0],[0,1],[0,2],[0,3],[0,4],[0,5],[0,6],[0,7],[0,8],[0,9],[0,10],[0,11],[0,12],[0,13],[0,14],[1,0],[1,14],[2,0],[2,2],[2,4],[2,6],[2,8],[2,10],[2,12],[2,14],[3,0],[3,14],[4,0],[4,2],[4,4],[4,6],[4,8],[4,10],[4,12],[4,14],[5,0],[5,14],[6,0],[6,2],[6,4],[6,6],[6,8],[6,10],[6,12],[6,14],[7,0],[7,14],[8,0],[8,2],[8,4],[8,6],[8,8],[8,10],[8,12],[8,14],[9,0],[9,14],[10,0],[10,2],[10,4],[10,6],[10,8],[10,10],[10,12],[10,14],[11,0],[11,14],[12,0],[12,2],[12,4],[12,6],[12,8],[12,10],[12,12],[12,14],[13,0],[13,14],[14,0],[14,1],[14,2],[14,3],[14,4],[14,5],[14,6],[14,7],[14,8],[14,9],[14,10],[14,11],[14,12],[14,13],[14,14]],"blocks":[[13,6],[7,6],[2,3],[13,10],[11,4],[8,11],[5,10],[7,3],[9,10],[11,2],[1,9],[3,7],[11,13],[8,13],[3,9],[3,6],[4,13],[10,13],[9,7],[9,12],[9,4],[11,12],[9,5],[10,7],[5,7],[9,6],[2,7],[4,1],[4,3],[7,5],[7,4],[5,2],[3,1],[12,5],[4,7],[6,13],[8,5],[8,3],[7,9],[9,8],[1,11],[11,1],[8,7],[10,3],[11,10],[3,2],[7,8],[10,1],[5,11],[5,3],[7,2],[11,7],[13,11],[4,9],[9,13],[1,5],[5,9],[1,8],[11,9],[6,7],[8,1],[12,7],[7,7],[2,5],[10,5],[5,6],[9,9],[3,11],[9,1],[7,11],[13,9],[10,9],[1,7],[1,3],[1,4],[9,3],[4,5],[1,6],[13,8],[11,5],[3,5],[4,11],[3,10],[2,11],[11,11],[6,5],[3,8],[3,4],[10,11],[7,1]],"players":[{"name":"ハツネツAI","pos":{"x":1,"y":1},"power":2,"setBombLimit":2,"ch":"ハ","isAlive":true,"setBombCount":0,"totalSetBombCount":0,"id":0},{"name":"予定地","pos":{"x":1,"y":13},"power":2,"setBombLimit":2,"ch":"予","isAlive":true,"setBombCount":0,"totalSetBombCount":0,"id":1},{"name":"ハツネツAI","pos":{"x":13,"y":1},"power":2,"setBombLimit":2,"ch":"ハ","isAlive":true,"setBombCount":0,"totalSetBombCount":0,"id":2},{"name":"ハツネツAI","pos":{"x":13,"y":13},"power":2,"setBombLimit":2,"ch":"ハ","isAlive":true,"setBombCount":0,"totalSetBombCount":0,"id":3}],"bombs":[],"items":[],"fires":[]}'

expected_rendering = <<EOS
■■■■■■■■■■■■■■■
■ハ　□□　　□□□□□　ハ■
■　■□■□■□■　■□■　■
■□□　□□　□□□□　　　■
■□■□■　■□■□■□■　■
■□□□□　□□□□□□□　■
■□■□■□■□■□■　■□■
■□□□□□□□□□□□□　■
■□■□■　■□■□■　■□■
■□　□□□　□　□□□　□■
■　■□■□■　■□■□■□■
■□□□□□　□□　□□　□■
■　■　■　■　■□■□■　■
■予　　□　□　□□□□　ハ■
■■■■■■■■■■■■■■■
EOS

require_relative 'show_map'

describe 'GameStateクラス' do
  it 'ほげ' do
    expect(GameState.new(init_state).class).to eq GameState
  end
  it 'ふが' do
    expect(show_map(GameState.new(init_state))).to eq expected_rendering
  end
end
