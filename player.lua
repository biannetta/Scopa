local Object = require "classic"
local Card = require "card"
local Player = Object:extend()

function Player:new(id, name)
  self.id = id
  self.name = name
  self.hand = {}
  self.selectedCard = nil
  self.capturedCards = {}
  self.scopas = 0
  self.score = 0
end

function Player:selectCard(card)
  self.selectedCard = card
end

function Player:addScopa()
  self.scopas = self.scopas + 1
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

function Player:calculateScore(numPlayers, deckSize)
  local roundScore = {}

  -- Add scopas
  self.score = self.score + self.scopas
  roundScore['scopas'] = self.scopas

  -- Point for most cards
  roundScore['cardCount'] = self:totalCaptured()
  if self:totalCaptured() > (deckSize/numPlayers) then
    self.score = self.score + 1
  end

  if Card:hasSetteBello(self.capturedCards) then
    self.score = self.score + 1
    roundScore['setteBello'] = 1
  end

  return roundScore

end

function Player:reset()
  self.hand = {}
  self.selectedCard = nil
  self.capturedCards = {}
  self.scopas = 0
end

function Player:toString()
  return self.name
end

return Player