function love.load()
  cardHeight = 100
  cardWidth = 63
  
  cardSheet = love.graphics.newImage("Spada_Cards_Label.png")

  toastMessages = nil
  toastLength = 5

  game = {
    deck = {},
    players = {},
    field = {},
    cursor = 1,
    currentPlayer = 1,
    currentSelection = {},
    state = "HAND",
    
    activePlayer = function(self)
      return self.players[self.currentPlayer]
    end,

    activeSet = function(self)
      if self.state == "HAND" then
        return self:activePlayer().hand
      elseif self.state == "FIELD" then
        return self.field
      end
    end,
    
    advancePlayer = function(self)
      self.currentPlayer = self.currentPlayer + 1
      if self.currentPlayer > #self.players then
        self.currentPlayer = 1
      end
    end,

    clearSelection = function(self)
      self.currentSelection = nil
    end,

    dealNewCards = function(self)
      local handCount = 0

      for _,player in ipairs(self.players) do
        if player.hand ~= nil then
          handCount = handCount + #player.hand
        end
      end

      return handCount == 0
    end,

    playCard = function(self)
    end,

    nextTurn = function(self)
      if self.deck == nil then
        print("Game Over")
      else
        self:resetCursor()
        self:advancePlayer()
        self:selectHand()
        
        self:activePlayer().selectedCard = nil
        self.currentSelection = nil

        if self:dealNewCards() then
          dealPlayers(self.players, self.deck)
        end
      end
    end,

    incrementCursor = function(self)
      self.cursor = self.cursor + 1
      if self.cursor > #self:activeSet() then
        self.cursor = 1
      end
    end,
    
    decrementCursor = function(self)
      self.cursor = self.cursor - 1
      if self.cursor < 1  then
        self.cursor = #self:activeSet()
      end
    end,

    resetCursor = function(self)
      self.cursor = 1
    end,

    selectedCard = function(self)
      return self:activeSet()[self.cursor]
    end,

    selectHand = function(self)
      self:activePlayer().selectedCard = nil
      self:clearSelection()
      self.state = "HAND"
    end,

    selectField = function(self)
      self.state = "FIELD"
      self.currentSelection = {}
      self:resetCursor()
    end
  }
  
  function initializeDeck(deck)   
    local suits = { 'C', 'D', 'S', 'B' }
    local ranks = { '1','2','3','4','5','6','7','J','Q','K' }

    for i,suit in ipairs(suits) do
      for j,rank in ipairs(ranks) do
        table.insert(deck,{
          suit = suit,
          rank = rank,
          value = j,
          toString = function(self)
            return rank..suit
          end
        })
      end
    end

    for i=#deck,1,-1 do
      local j = love.math.random(i)
      local temp = deck[i]
      deck[i] = deck[j]
      deck[j] = temp
    end
  end
  
  function dealCards(hand, noCards, deck)
    for j=1,noCards do
      table.insert(hand, table.remove(deck,1))
    end 
  end

  function dealPlayers(players, deck)
    for i=1,#players do
      dealCards(players[i].hand,3, deck)      
    end
  end

  function isCardInSet(targetCard, set, matchOption)
    matchOption = matchOption or 0
    local cardInSet = false

    if set == nil or targetCard == nil then
      return false
    end

    for i,card in ipairs(set) do
      if matchOption == 0 and card == targetCard then
        cardInSet = true
      elseif matchOption == 1 and card.value == targetCard.value then
        cardInSet = true
      end
    end

    return cardInSet
  end

  function toggleSelection(selectedCard, selection)
    local x = 0

    for i,card in ipairs(selection) do
      if card == selectedCard then
        x = i
      end
    end

    if x > 0 then
      table.remove(selection, x)
    else
      table.insert(selection, selectedCard)
    end
  end

  function summarizeSelection(set)
    local sum = 0

    if set ~= nil then
      for _,card in ipairs(set) do
        sum = sum + card.value
      end
    end

    return sum
  end

  function removeCards(hand, cardsToRemove)
    for i,remove in ipairs(cardsToRemove) do
      for j,card in ipairs(hand) do
        if remove == card then
          table.remove(hand,j)
        end
      end
    end
  end

  function captureCards(targetCard, selection)
    if targetCard.value ~= summarizeSelection(selection) then
      return false
    end

    if isCardInSet(targetCard, game.field, 1) and #selection ~= 1 then
      return false
    end

    local capturedCards = {}
      
    table.insert(capturedCards, game.currentSelection)
    table.insert(capturedCards, game:activePlayer().selectedCard)
    table.insert(game:activePlayer().capturedCards, capturedCards)

    removeCards(game:activePlayer().hand, { game:activePlayer().selectedCard })
    removeCards(game.field, game.currentSelection)

    return true
  end

  function moveCardToSet(fromSet, card, toSet)
    table.insert(toSet, card)
    removeCards(fromSet, { card })
  end

  function layCardInField(targetCard)
    if isCardInSet(game:activePlayer().selectedCard, game.field, 1) then
      return false
    end

    moveCardToSet(game:activePlayer().hand, targetCard, game.field)
    
    return true
  end

  function startGame()
    local maxPlayers = 2

    for i=1,maxPlayers do
      table.insert(game.players, {
        name = "Player "..i,
        hand = {},
        selectedCard = nil,
        capturedCards = {},
        totalCaptured = function(self)
          if self.capturedCards == nil then
            return 0
          else
            return #self.capturedCards
          end
        end
      })
    end
    
    initializeDeck(game.deck)
    dealPlayers(game.players, game.deck)
    dealCards(game.field, 4, game.deck)
  end

  startGame()

end

function love.update(dt)
  if toastMessages ~= nil then
    toastLength = toastLength - dt
  end
  
  if toastLength < 0 then
    toastMessages = nil
    toastLength = 5
  end
end

function love.draw()
  local function drawCard(card, xPos, yPos, highlight, selected) 
    local textOffsetX = xPos + 5
    local textOffsetY = yPos + 5
    local xOffset = ((card.value - 1) * cardWidth) + (card.value - 1)
    local cardQuad = love.graphics.newQuad(xOffset, 0, cardWidth, cardHeight, cardSheet)
    
    love.graphics.setColor(1, 1, 1)
    
    if highlight then
      love.graphics.setColor(1, 1, 0)
      love.graphics.setLineWidth(2)
      love.graphics.rectangle("line", xPos - 2, yPos - 2, cardWidth + 4, cardHeight + 4, 5)
    end

    if selected then
      love.graphics.setColor(1, 1, 0)
    else
      love.graphics.setColor(1, 1, 1)
    end

    love.graphics.draw(cardSheet, cardQuad, xPos, yPos)
  end

  local function drawHand(hand, selection, xPos, yPos, active)
    for j,card in ipairs(hand) do
      local isHighlighted = (active and j == game.cursor)
      local isSelected = isCardInSet(card, selection)
      drawCard(card, xPos + (cardWidth + 10) * (j - 1), yPos, isHighlighted, isSelected)
    end 
  end

  love.graphics.setBackgroundColor(0.1, 0.1, 0.15)
  love.graphics.setColor(1, 1, 1)
  
  -- Display Player Hands
  for i,player in ipairs(game.players) do
    local startX = (500 * (i - 1)) + 10
    local activeHand = game:activePlayer() == player and game.state == "HAND"
    
    love.graphics.setColor(1, 1, 1)
    love.graphics.print(player.name..' Hand', startX, 10)
    love.graphics.print('Total Captured '..player:totalCaptured(), startX + 100, 10)
    drawHand(player.hand, { player.selectedCard }, startX, 35, activeHand)
  end
  
  -- Display Field
  love.graphics.setColor(1, 1, 1)
  love.graphics.print('Field:', 10, 50 + cardHeight)
  drawHand(game.field, game.currentSelection, 10, 70 + cardHeight, (game.state == "FIELD"))


  love.graphics.setColor(1, 1, 1)
  love.graphics.print('Current Selected Value: '..summarizeSelection(game.currentSelection), 10, 85 + (cardHeight * 2))
  love.graphics.print('Cards Remaining: '..#game.deck, 10, 110 + (cardHeight * 2))
  love.graphics.print('User arrow keys and press "space" to select a card. Press "enter" to capture cards, press "x" to lay selected card on table', 10, 135 + (cardHeight * 2))

  if toastMessages ~= nil then
    love.graphics.print(toastMessages, 10, 155 + (cardHeight * 2))
  end
end

function love.keypressed(key)
  if key == "j" or key == "left" then
    game:decrementCursor() 
  end
  
  if key == "k" or key == "right" then
    game:incrementCursor()
  end

  if key == "u" and game.state == "FIELD" then
    game:resetCursor()
    game:selectHand()
  end

  if key == "space" then
    if game.state == "HAND" then
      game:activePlayer().selectedCard = game:selectedCard()
      game:selectField()
    elseif game.state == "FIELD" then
      toggleSelection(game:selectedCard(), game.currentSelection)
    end
  end

  if key == "return" and game:activePlayer().selectedCard ~= nil then
    if captureCards(game:activePlayer().selectedCard, game.currentSelection) then
      game:nextTurn()
    else
      toastMessages = "Cannot capture selected cards"
    end
  end

  if key == "x" and game:activePlayer().selectedCard ~= nil then 
    if layCardInField(game:activePlayer().selectedCard) then
      game:nextTurn()
    else
      toastMessages = "Card cannot be layed. There are capturable cards in the field"
    end
  end
end