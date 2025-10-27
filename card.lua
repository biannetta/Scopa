local Object = require "classic"
local Card = Object:extend()

Card.height = 100
Card.width = 63
Card.scale = 1.25
Card.margin = 5
Card.sprites = {
  SPADE = love.graphics.newImage("assets/Spada_Cards_Label.png"),
  DENARI = love.graphics.newImage("assets/Denari_Cards_Label.png"),
  COPPE = love.graphics.newImage("assets/Spada_Cards_Label.png"),
  BASTONI = love.graphics.newImage("assets/Denari_Cards_Label.png"),
  BACK = love.graphics.newImage("assets/Card_Backs.png")
}
Card.suits = { 'COPPE', 'DENARI', 'SPADE', 'BASTONI' }
Card.ranks = { '1','2','3','4','5','6','7','J','Q','K' }

function Card:new(rank, suit, value)
  self.rank = rank
  self.suit = suit
  self.value = value
end

function Card:getDisplayWidth()
  return (Card.width * Card.scale) + (Card.margin * 2)
end

function Card:getDisplayHeight()
  return (Card.height * Card.scale) + (Card.margin * 2)
end

function Card:toString()
  return self.rank.." of "..self.suit
end

function Card:draw(xPos, yPos, highlight, selected)
  local cardSprite = Card.sprites[self.suit]
  local cardOffset = ((self.value - 1) * Card.width) + (self.value - 1)
  local cardQuad = love.graphics.newQuad(cardOffset, 0, Card.width, Card.height, cardSprite)

  love.graphics.setColor(1, 1, 1)
  
  if highlight then
    love.graphics.setColor(1, 1, 0)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", xPos - 2, yPos - 2, Card.width * Card.scale + 4, Card.height * Card.scale + 4, 5)
  end

  if selected then
    love.graphics.setColor(1, 1, 0)
  else
    love.graphics.setColor(1, 1, 1)
  end

  love.graphics.draw(cardSprite, cardQuad, xPos, yPos, 0, Card.scale, Card.scale)
end

function Card:drawBack(xPos, yPos)
  local cardQuad = love.graphics.newQuad(0, 0, 63, 100, Card.sprites.BACK)

  love.graphics.draw(Card.sprites.BACK, cardQuad, xPos, yPos, 0, Card.scale, Card.scale)
end

return Card