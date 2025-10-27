local Object = require "classic"
local Deck = require "deck"
local Card = require "card"
local Player = require "player"
local Game = Object:extend()

Game.states = {
  HAND = 1,
  FIELD = 2
}

function Game:new()
  self.deck = Deck()
  self.players = {}
  self.field = {}
  self.cursor = 1
  self.activePlayer = nil
  self.currentSelection = {}
  self.state = Game.states.HAND
end

function Game:init(numPlayers)
  for i=1,numPlayers do
    self.players[i] = Player(i,"Player "..i)
  end

  self:dealPlayers()
  self.field = self.deck:dealCards(4)
  self.activePlayer = self.players[1]
end

function Game:dealPlayers()
  for _,player in ipairs(self.players) do
    player.hand = self.deck:dealCards(3)      
  end
end

function Game:activeSet()
  if self.state == Game.states.HAND then
    return self.activePlayer.hand
  else
    return self.field
  end
end
    
function Game:nextPlayer()
  local index = self.activePlayer.id

  index = index + 1
  if index > #self.players then
    index = 1
  end
  self.activePlayer = self.players[index]
end

function Game:sumOfSet(set)
  local sum = 0
  
  for _,card in ipairs(set) do
    sum = sum + card.value
  end
  
  return sum
end

function Game:isCardInSet(targetCard, set, matchType)
  local inSet = false
  matchType = matchType or "CARD"

  if targetCard == nil or set == nil then
    return inSet
  end

  for i,card in ipairs(set) do
    if matchType == "CARD" and card == targetCard then
      inSet = true
    elseif matchType == "VALUE" and card.value == targetCard.value then
      inSet = true
    end
  end
  
  return inSet
end

function Game:hasValidCaptures(target, set, cards, start)
  if #cards == 0 then
    -- searched all cards
    return false
  elseif target == self:sumOfSet(set) then
    -- found a valid captures
    return true
  elseif start > #cards then
    -- reduce the available cards by 1
    table.remove(cards, 1)
    return self:hasValidCaptures(target, {}, cards, 1)
  else
    -- check set with next card
    local newSet = table.insert(set, cards[start])
    return self:hasValidCaptures(target, set, cards, start + 1)
  end
end

function Game:isValidMove()
  if self.activePlayer.selectedCard == nil then
    -- Player has not selected a card for capture
    print("Player has not selected a card")
    return false
  end

  local fieldCopy = {}
  for i,card in ipairs(self.field) do
    fieldCopy[i] = card
  end

  if #self.currentSelection == 0 and self:hasValidCaptures(self.activePlayer.selectedCard.value, {}, fieldCopy, 1) then
    -- Valid captures for players selected card
    print("Player has valid captures for selected card")
    return false
  end

  if #self.currentSelection > 0 and self.activePlayer.selectedCard.value ~= self:sumOfSet(self.currentSelection) then
    -- Selection does not equal selected card value
    print("Player selection does not match selected card")
    return false
  end

  if self:isCardInSet(self.activePlayer.selectedCard, self.currentSelection, "VALUE") and #self.currentSelection ~= 1 then
    -- User must select matching card in field
    print("Player attempting to capture card other than exact match")
    return false
  end

  return true
end

function Game:removeCards(set, cardsToRemove)
  for i,remove in ipairs(cardsToRemove) do
    for j,card in ipairs(set) do
      if remove == card then
        table.remove(set,j)
      end
    end
  end
end

function Game:captureCards()
  if #self.currentSelection > 0 then
    self.activePlayer:captureCards(self.currentSelection)
    self:removeCards(self.field, self.currentSelection)
  else
    table.insert(self.field, self.activePlayer.selectedCard)
  end
  self:removeCards(self.activePlayer.hand, { self.activePlayer.selectedCard })
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
  self:nextPlayer()
  self:selectHand()
  self:updateState(Game.states.HAND)
  
  if self:dealNewCards() and self.deck:count() == 0 then
    toastMessages = "Round Over"
  elseif self:dealNewCards() then
    self:dealPlayers(self.players, self.deck)
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

function Game:updateState(newState)
  self.state = newState
  self.currentSelection = {}
  self.cursor = 1
end

function Game:selectedCard()
  return self:activeSet()[self.cursor]
end

function Game:selectCard()
  if self.state == Game.states.HAND then
    self.activePlayer:selectCard(self:selectedCard())
    self:selectField()
  else
    self:toggleFieldSelection(self:selectedCard())
  end
end

function Game:toggleFieldSelection(selectedCard)
  local x = 0

  for i,card in ipairs(self.currentSelection) do
    if card == selectedCard then
      x = i
    end
  end

  if x > 0 then
    table.remove(self.currentSelection, x)
  else
    table.insert(self.currentSelection, selectedCard)
  end
end

function Game:selectHand()
  if self.state == Game.states.FIELD then
    self.activePlayer.selectedCard = nil
    self:updateState(Game.states.HAND)
  end
end

function Game:selectField()
  if self.state == Game.states.HAND then
    self:updateState(Game.states.FIELD)
  end
end

-- Drawing Functions
function Game:drawPlayerHand(player, xPos, yPos)
  if player:totalCaptured() > 0 then
    Card:drawBack(xPos, yPos)
  else
    love.graphics.rectangle('line', xPos, yPos, Card.width * Card.scale, Card.height * Card.scale, 5)
  end
  
  for j,card in ipairs(player.hand) do
    local isSelected = card == player.selectedCard
    local xOffset = Card:getDisplayWidth() * j
    local isActive = self.activePlayer == player and self.state == Game.states.HAND and j == self.cursor
    card:draw(xPos + xOffset, yPos, isActive, isSelected)
  end 
end

function Game:drawField(xPos, yPos)
  for j,card in ipairs(self.field) do
    local active = self.state == Game.states.FIELD and self.cursor == j
    local xOffset = Card:getDisplayWidth() * (j-1)
    card:draw(xPos + xOffset, yPos, active, self:isCardInSet(card, self.currentSelection))
  end
end

return Game   