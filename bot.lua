local Player = require "player"
local Bot = Player:extend()

function Bot:new(id, name)
  Bot.super.new(self, id, name)
  self.isBot = true
end

function Bot:makeMove(field)
  print("Bot making move")

  for _, card in ipairs(self.hand) do
    print(card:toString())
  end

end

return Bot