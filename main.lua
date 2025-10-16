function love.load()
  
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

    nextTurn = function(self)
      self:resetCursor()
      self:advancePlayer()
      self:selectHand()
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

  function isCardInSet(targetCard, set)
    local cardInSet = false

    if set == nil or targetCard == nil then
      return false
    end

    for i,card in ipairs(set) do
      if card == targetCard then
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
    if targetCard.value == summarizeSelection(selection) then
      local capturedCards = {}
      
      table.insert(capturedCards, game.currentSelection)
      table.insert(capturedCards, game:activePlayer().selectedCard)
      table.insert(game:activePlayer().capturedCards, capturedCards)

      removeCards(game:activePlayer().hand, { game:activePlayer().selectedCard })
      removeCards(game.field, game.currentSelection)

      game:activePlayer().selectedCard = nil
      game.currentSelection = nil

      game:nextTurn()
    else
      print('Cards cannot be captured')
    end
  end

  function layCardInField(targetCard, field)
    table.insert(field, targetCard)

    removeCards(game:activePlayer().hand, { targetCard })

    game:activePlayer().selectedCard = nil
    game.currentSelection = nil

    game:nextTurn()
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

function love.draw()
  local cardHeight = 160
  local cardWidth = 120
  local cardCorner = 10  
  
  local function drawCard(text, xPos, yPos, highlight, selected) 
    local textOffsetX = xPos + 5
    local textOffsetY = yPos + 5
    
    if highlight then
      love.graphics.setColor(1, 1, 0, 0.3)
      love.graphics.rectangle("fill", xPos - 5, yPos - 5, cardWidth + 10, cardHeight + 10, cardCorner)

      love.graphics.setColor(1, 1, 0)
      love.graphics.setLineWidth(3)
      love.graphics.rectangle("line", xPos - 5, yPos - 5, cardWidth + 10, cardHeight + 10, cardCorner)
    end

    if selected then
      love.graphics.setColor(0.45, 0.65, 0.8)
    else
      love.graphics.setColor(0.2, 0.5, 0.9)
    end
    love.graphics.rectangle('fill', xPos, yPos, cardWidth, cardHeight, cardCorner)
    
    love.graphics.setColor(0, 0, 0)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", xPos, yPos, cardWidth, cardHeight, cardCorner)

    love.graphics.setColor(1, 1, 1)
    love.graphics.print(text, textOffsetX, textOffsetY)
  end

  local function drawHand(hand, selection, xPos, yPos, active)
    for j,card in ipairs(hand) do
      local isHighlighted = (active and j == game.cursor)
      local isSelected = isCardInSet(card, selection)
      drawCard(card:toString(), xPos + (cardWidth + 10) * (j - 1), yPos, isHighlighted, isSelected)
    end 
  end

  love.graphics.setBackgroundColor(0.1, 0.1, 0.15)
  love.graphics.setColor(1, 1, 1)
  
  -- Display Player Hands
  for i,player in ipairs(game.players) do
    local startX = (500 * (i - 1)) + 10
    local activeHand = game:activePlayer() == player and game.state == "HAND"

    love.graphics.print(player.name..' Hand', startX, 10)
    love.graphics.print('Total Captured '..player:totalCaptured(), startX + 100, 10)
    drawHand(player.hand, { player.selectedCard }, startX, 35, activeHand)
  end
  
  -- Display Field
  love.graphics.setColor(1, 1, 1)
  love.graphics.print('Field:', 10, 50 + cardHeight)
  drawHand(game.field, game.currentSelection, 10, 70 + cardHeight, (game.state == "FIELD"))
  love.graphics.print('Current Selected Value: '..summarizeSelection(game.currentSelection), 10, 85 + (cardHeight * 2))
  
  -- Display Insructions
  love.graphics.setColor(1, 1, 1)
  love.graphics.print('Cards Remaining: '..#game.deck, 10, 110 + (cardHeight * 2))
  love.graphics.print('User arrow keys and press "space" to select a card.', 10, 135 + (cardHeight * 2))
end

function love.keypressed(key)
  if key == "j" or key == "left" then
    game:decrementCursor() 
  end
  
  if key == "k" or key == "right" then
    game:incrementCursor()
  end

  if key == "u" and game.state == "FIELD" then
    game:activePlayer().selectedCard = nil
    game:selectHand()
    game.currentSelection = {}
  end

  if key == "space" then
    if game.state == "HAND" then
      game:activePlayer().selectedCard = game:selectedCard()
      game:selectField()
    elseif game.state == "FIELD" then
      toggleSelection(game:selectedCard(), game.currentSelection)
    end
  end

  if key == "return" then
    local selectedCard = game:activePlayer().selectedCard

    if selectedCard ~= nil then
      captureCards(selectedCard, game.currentSelection)
    end
  end

  if key == "x" then
    layCardInField(game:activePlayer().selectedCard, game.field)
  end
end