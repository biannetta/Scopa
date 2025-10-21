local Object = require "classic"
local Card = Object:extend()

Card.height = 100
Card.width = 63
Card.sprites = {
  SPADA = love.graphics.newImage("Spada_Cards_Label.png")
}

function Card:new(rank, suit, value)
  self.rank = rank
  self.suit = suit
  self.value = value
end

function Card:toString()
  return rank.." of "..suit
end

function Card:draw(xPos, yPos, highlight, selected)
  local textOffsetX = xPos + 5
  local textOffsetY = yPos + 5
  local xOffset = ((self.value - 1) * Card.width) + (self.value - 1)
  local cardQuad = love.graphics.newQuad(xOffset, 0, Card.width, Card.height, Card.sprites.SPADA)
  
  love.graphics.setColor(1, 1, 1)
  
  if highlight then
    love.graphics.setColor(1, 1, 0)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", xPos - 2, yPos - 2, Card.width + 4, Card.height + 4, 5)
  end

  if selected then
    love.graphics.setColor(1, 1, 0)
  else
    love.graphics.setColor(1, 1, 1)
  end

  love.graphics.draw(Card.sprites.SPADA, cardQuad, xPos, yPos)
end

return Card