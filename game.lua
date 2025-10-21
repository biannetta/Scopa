local Object = require "classic"
local Deck = require "deck"
local Player = require "player"
local Game = Object:extend()

function Game:new(numPlayers)
  self.deck = Deck()
  self.maxPlayers = numPlayers or 2
  self.players = {}
  self.field = {}
  self.cursor = 1
  self.currentPlayer = 1
  self.currentSelection = {}
  self.state = "HAND"
  
  for i=1,self.maxPlayers do
    self.players[i] = Player("Player "..i)
  end
end

function Game:activePlayer()
  return self.players[self.currentPlayer]
end

function Game:activeSet()
  if self.state == "HAND" then
    return self:activePlayer().hand
  elseif self.state == "FIELD" then
    return self.field
  end
end
    
function Game:advancePlayer()
  self.currentPlayer = self.currentPlayer + 1
  if self.currentPlayer > #self.players then
    self.currentPlayer = 1
  end
end

function Game:clearSelection()
  self.currentSelection = nil
end

function Game:dealNewCards()
  local handCount = 0

  for _,player in ipairs(self.players) do
    if player.hand ~= nil then
      handCount = handCount + #player.hand
    end
  end

  return handCount == 0
end

function Game:nextTurn()
  self:resetCursor()
  self:advancePlayer()
  self:selectHand()
  
  self:activePlayer().selectedCard = nil
  self.currentSelection = nil

  if self:dealNewCards() and self.deck:count() == 0 then
    toastMessages = "Round Over"
  elseif self:dealNewCards() then
    dealPlayers(self.players, self.deck)
  end
end

function Game:incrementCursor()
  self.cursor = self.cursor + 1
  if self.cursor > #self:activeSet() then
    self.cursor = 1
  end
end
    
function Game:decrementCursor()
  self.cursor = self.cursor - 1
  if self.cursor < 1  then
    self.cursor = #self:activeSet()
  end
end

function Game:resetCursor()
  self.cursor = 1
end

function Game:selectedCard()
  return self:activeSet()[self.cursor]
end

function Game:selectHand()
  self:activePlayer().selectedCard = nil
  self:clearSelection()
  self.state = "HAND"
end

function Game:selectField()
  self.state = "FIELD"
  self.currentSelection = {}
  self:resetCursor()
end

return Game   