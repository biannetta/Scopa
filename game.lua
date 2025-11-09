local Object = require "classic"
local Deck = require "deck"
local Card = require "card"
local Player = require "player"
local Bot = require "bot"
local Game = Object:extend()

Game.states = {
  HAND = 1,
  FIELD = 2,
  PAUSE = 3
}

function Game:new()
  self.deck = nil
  self.targetScore = 11
  self.numPlayers = 0
  self.players = {}
  self.field = {}
  self.cursor = 1
  self.activePlayer = nil
  self.currentSelection = {}
  self.lastCapture = nil
  self.previousState = nil
  self.state = Game.states.HAND
  self.messages = {}
  self.messageLength = 5
  self.playerScores = {}
end

function Game:init(numPlayers, numBots)
  self.numPlayers = numPlayers

  -- Create Human Players
  for i=1,(numPlayers - numBots) do
    self.players[i] = Player(i,"Player "..i)
    self.playerScores[i] = {}
  end

  -- Create Bots
  for i=#self.players + 1, numPlayers do
    self.players[i] = Bot(i, "Bot "..i)
    self.playerScores[i] = {}
  end 

  self.deck = Deck()
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

function Game:isPaused()
  return self.state == Game.states.PAUSE
end

function Game:togglePause()
  if self:isPaused() then
    self:updateState(self.previousState)
  else
    self:updateState(Game.states.PAUSE)
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

function Game:addMessage(msg)
  table.insert(self.messages, msg)
end

function Game:updateMessage(dt)
  if #self.messages > 0 then
    self.messageLength = self.messageLength - dt
  end
  
  if self.messageLength < 0 then
    table.remove(self.messages, 1)
    self.messageLength = 5
  end
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
  if self:sumOfSet(set) == target then
    -- found a valid captures
    return true
  end

  if self:sumOfSet(set) > target or start > #cards then
    -- no more cards or sum larger than target
    return false
  end

  table.insert(set, cards[start])
  if self:hasValidCaptures(target, set, cards, start + 1) then
    return true
  end
  table.remove(set)
  
  return self:hasValidCaptures(target, set, cards, start + 1)
end

function Game:isValidMove()
  if self.activePlayer.selectedCard == nil then
    -- Player has not selected a card for capture
    self:addMessage("No card selected")
    return false
  end

  if #self.currentSelection == 0 and self:hasValidCaptures(self.activePlayer.selectedCard.value, {}, self.field, 1) then
    -- Valid captures for players selected card
    self:addMessage("Valid captures available")
    return false
  end

  if #self.currentSelection > 0 and self.activePlayer.selectedCard.value ~= self:sumOfSet(self.currentSelection) then
    -- Selection does not equal selected card value
    self:addMessage("Selection does not match selected card")
    return false
  end

  if self:isCardInSet(self.activePlayer.selectedCard, self.field, "VALUE") and #self.currentSelection ~= 1 then
    -- User must select matching card in field
    self:addMessage("Must capture exact match")
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
    if #self.currentSelection == #self.field then
      self.activePlayer:addScopa()
    end

    self.activePlayer:captureCards(self.currentSelection)
    self:removeCards(self.field, self.currentSelection)
    self.lastCapture = self.activePlayer
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

  if self.activePlayer.isBot then
    self.activePlayer:makeMove(self.field)
  end
  
  if self:dealNewCards() and self.deck:count() == 0 then
    self:nextRound()
  elseif self:dealNewCards() then
    self:dealPlayers(self.players, self.deck)
  end
end

function Game:nextRound()
  if #self.field > 0 then
    self.lastCapture:captureCards(self.field)
    self.field = {}
  end

  for i,player in ipairs(self.players) do
    table.insert(self.playerScores[i],player:calculateScore(self.numPlayers, 40))
    player:reset()
  end

  if not self:checkForGameOver() then
    self:addMessage("Dealing New Round")
    self.deck:reshuffle()
    self:dealPlayers()
    self.field = self.deck:dealCards(4)
    self.activePlayer = self.players[1]
  else
    self:addMessage("Game Over. "..self.winningPlayer:toString().." wins!")
  end
end

function Game:checkForGameOver()
  local gameOver = false
  local winningScore = 0

  for i,player in ipairs(self.players) do
    if player.score >= self.targetScore and player.score > winningScore then
      gameOver = true
      winningScore = player.score
      self.winningPlayer = player
    end
  end

  return gameOver
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
  self.previousState = self.state
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
function Game:drawDeck(xPos, yPos)
  if self.deck:count() == 0 then
    love.graphics.rectangle('line', xPos, yPos, Card.width * Card.scale, Card.height * Card.scale, 5)
  else
    Card:drawBack(xPos, yPos)
  end
  love.graphics.print(self.deck:count().." out of "..self.deck.size, xPos, yPos + Card:getDisplayHeight())
end

function Game:drawPlayerHand(player, xPos, yPos)
  love.graphics.setColor(1, 1, 1)
  love.graphics.print(player.name, xPos, yPos - 50)
  love.graphics.print('Captured: '..player:totalCaptured()..' Scopas: '..player.scopas..' Score: '..player.score, xPos, yPos - 25)
  
  if player.scopas > 0 then
    player.capturedCards[1]:draw(xPos - 45, yPos + 100, false, false, true)
  end

  if player:totalCaptured() > 0 then
    Card:drawBack(xPos, yPos)
  else
    love.graphics.rectangle('line', xPos, yPos, Card.width * Card.scale, Card.height * Card.scale, 5)
  end
  
  for j,card in ipairs(player.hand) do
    local isSelected = card == player.selectedCard
    local xOffset = Card:getDisplayWidth() * j
    local isActive = self.activePlayer == player and self.state == Game.states.HAND and j == self.cursor

    if (player.isBot) then
      Card:drawBack(xPos + xOffset, yPos)
    else
      card:draw(xPos + xOffset, yPos, isActive, isSelected)
    end
  end 
end

function Game:drawField(xPos, yPos)
  love.graphics.print('Current Selected Value: '..self:sumOfSet(game.currentSelection), xPos, yPos - 25)
  for j,card in ipairs(self.field) do
    local active = self.state == Game.states.FIELD and self.cursor == j
    local xOffset = Card:getDisplayWidth() * (j-1)
    card:draw(xPos + xOffset, yPos, active, self:isCardInSet(card, self.currentSelection))
  end
end

function Game:displayMessages(xPos, yPos)
  if #self.messages > 0 then
    love.graphics.print(self.messages[1], xPos, yPos + 50)
  end
end

function Game:printScoreSummary(xPos, yPos)
  local xOffset = 0
  local yOffset = 0

  love.graphics.setColor(0.278, 0.278, 0.278, 0.75)
  love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
  
  love.graphics.setColor(1, 1, 1)
  for i,playerScore in ipairs(self.playerScores) do
    xOffset = (i-1) * 250
    love.graphics.print('Player '..i..' score:', xPos + xOffset, yPos)
    for j,scores in pairs(playerScore) do
      local keyIterator = 0
      yOffset = j * 25
      love.graphics.print('Round '..j, xPos + xOffset, yPos + yOffset)
      for key,pair in pairs(scores) do
        keyIterator = keyIterator + 1
        yOffset = keyIterator * 50
        love.graphics.print(key..': '..pair, xPos + xOffset, yPos + yOffset)
      end
    end
  end
end

return Game   