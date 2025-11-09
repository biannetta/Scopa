local Object = require "classic"
local Card = require "card"
local Deck = Object:extend()

function Deck:new(size)
  self.size = size or 40
  self._deck = {}

  self:init()
  self:shuffle()
end

function Deck:init()
  for i,suit in ipairs(Card.suits) do
    for j,rank in ipairs(Card.ranks) do
      table.insert(self._deck, Card(rank, suit, j))
    end
  end
end

function Deck:reshuffle()
  self:init()
  self:shuffle()
end

function Deck:shuffle()
  for i=self.size,1,-1 do
    local j = love.math.random(i)
    local temp = self._deck[i]
    
    self._deck[i] = self._deck[j]
    self._deck[j] = temp
  end
end

function Deck:count()
  if self._deck ~= nil then
    return #self._deck
  else
    return 0
  end
end

function Deck:dealCard()
  if self._deck ~= nil or #self._deck > 0 then
    return table.remove(self._deck, 1)
  else
    return nil
  end
end

function Deck:dealCards(noCards)
  local set = {}
  for j=1,noCards do
    table.insert(set, self:dealCard())
  end 

  return set
end

return Deck