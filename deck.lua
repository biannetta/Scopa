local Object = require "classic"
local Card = require "card"
local Deck = Object:extend()

local suits = { 'C', 'D', 'S', 'B' }
local ranks = { '1','2','3','4','5','6','7','J','Q','K' }

function Deck:new(size)
  self.size = size or 40
  self._deck = {}

  self:init()
  self:shuffle()
end

function Deck:init()
  for i,suit in ipairs(suits) do
    for j,rank in ipairs(ranks) do
      table.insert(self._deck, Card(suit, rank, j))
    end
  end
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

return Deck