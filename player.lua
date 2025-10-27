local Object = require "classic"
local Player = Object:extend()

function Player:new(id, name)
  self.id = id
  self.name = name
  self.hand = {}
  self.selectedCard = nil
  self.capturedCards = {}
end

function Player:selectCard(card)
  self.selectedCard = card
end

function Player:captureCards(captureSet)
  for _,card in ipairs(captureSet) do
    table.insert(self.capturedCards, card)
  end

  table.insert(self.capturedCards, self.selectedCard)
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