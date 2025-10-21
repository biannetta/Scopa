local Object = require "classic"
local Player = Object:extend()

function Player:new(name)
  self.name = name
  self.hand = {}
  self.selectedCard = nil
  self.capturedCards = {}
end

function Player:totalCaptured()
  if self.capturedCards == nil then
    return 0
  else
    return #self.capturedCards
  end
end

function Player:toString()
  return self.name
end

return Player