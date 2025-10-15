function love.load()
  -- variable inits
  deck = {}
  suits = { 'C', 'D', 'S', 'B' }
  ranks = { '1','2','3','4','5','6','7','J','Q','K' }
  players = {}
  field = {}
  activeSet = {}
  currentSelection = {}
  
  cardHeight = 160
  cardWidth = 120
  cardCorner = 10  
  
  function initializeDeck()   
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
  
  function dealCards(hand, noCards)
    for j=1,noCards do
      table.insert(hand, table.remove(deck,1))
    end 
  end

  function dealPlayers(players)
    for i=1,#players do
      dealCards(players[i].hand,3)      
    end
  end

  function selectField()
    activeSet = field
    currentCard = 1
    currentSelection = {}
  end

  function checkIfSelected(currentCard)
    local cardIsSelected = false

    if currentSelection ~= nil then
      for i,card in ipairs(currentSelection) do
        if card == currentCard then
          cardIsSelected = true
        end
      end
    end

    return cardIsSelected
  end

  function toggleSelection(selectedCard)
    local currenPosition = 0

    for i,card in ipairs(currentSelection) do
      if card == selectedCard then
        currenPosition = i
      end
    end

    if currenPosition > 0 then
      table.remove(currentSelection, currenPosition)
    else
      table.insert(currentSelection, selectedCard)
    end
  end

  function summarizeSelection()
    local sum = 0

    if currentSelection ~= nil then
      for _,card in ipairs(currentSelection) do
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

  function captureCards(targetCard)
    if targetCard.value == summarizeSelection() then
      local capturedCards = {}
      
      table.insert(capturedCards, currentSelection)
      table.insert(capturedCards, players[currentPlayer].selectedCard)
      table.insert(players[currentPlayer].capturedCards, capturedCards)
      print(players[currentPlayer]:totalCaptured())

      removeCards(players[currentPlayer].hand, { players[currentPlayer].selectedCard })
      removeCards(field, currentSelection)

      players[currentPlayer].selectedCard = nil
      currentSelection = nil

      nextPlayer()
    else
      print('Cards cannot be captured')
    end
  end

  function layCardInField(targetCard)
    table.insert(field, targetCard)

    removeCards(players[currentPlayer].hand, { targetCard })

    players[currentPlayer].selectedCard = nil
    currentSelection = nil

    nextPlayer()
  end

  function nextPlayer()
    currentCard = 1
    currentPlayer = currentPlayer + 1
    if currentPlayer > #players then
      currentPlayer = 1
    end
    activeSet = players[currentPlayer].hand
  end

  function startGame()
    table.insert(players, {
      name = "Player A",
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
    table.insert(players, {
      name = "Player B",
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

    field = {}
    
    initializeDeck()
    dealPlayers(players)
    dealCards(field, 4)

    currentPlayer = 1
    currentCard = 1
    activeSet = players[currentPlayer].hand
  end

  startGame()

end

function love.draw()
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

  local function drawHand(hand, xPos, yPos)
    for j,card in ipairs(hand) do
      local isHighlighted = (hand == activeSet and j == currentCard)
      local isSelected = players[currentPlayer].selectedCard == card
      drawCard(card:toString(), xPos + (cardWidth + 10) * (j - 1), yPos, isHighlighted, isSelected)
    end 
  end

  local function drawField(field, xPos, yPos)
    for j,card in ipairs(field) do 
      local isHighlighted = (field == activeSet and j == currentCard)
      local isSelected = checkIfSelected(card)
      drawCard(card:toString(), xPos + (cardWidth + 10) * (j - 1), yPos, isHighlighted, isSelected)
    end
  end

  love.graphics.setBackgroundColor(0.1, 0.1, 0.15)
  love.graphics.setColor(1, 1, 1)
  
  -- Display Player Hands
  for i,player in ipairs(players) do
    local startX = (500 * (i - 1)) + 10

    love.graphics.print(player.name..' Hand', startX, 10)
    love.graphics.print('Total Captured '..player:totalCaptured(), startX + 100, 10)
    drawHand(player.hand, startX, 35)
  end
  
  -- Display Field
  love.graphics.setColor(1, 1, 1)
  love.graphics.print('Field:', 10, 50 + cardHeight)
  drawField(field, 10, 70 + cardHeight)
  love.graphics.print('Current Selected Value: '..summarizeSelection(), 10, 85 + (cardHeight * 2))
  
  -- Display Insructions
  love.graphics.setColor(1, 1, 1)
  love.graphics.print('Cards Remaining: '..#deck, 10, 110 + (cardHeight * 2))
  love.graphics.print('User arrow keys and press "space" to select a card.', 10, 135 + (cardHeight * 2))
end

function love.keypressed(key)
  if key == "j" or key == "left" then
    currentCard = currentCard - 1
    if currentCard < 1  then
      currentCard = #activeSet
    end
  end
  
  if key == "k" or key == "right" then
    currentCard = currentCard + 1
    if currentCard > #activeSet then
      currentCard = 1
    end
  end

  if key == "u" and activeSet == field then
    activeSet = players[currentPlayer].hand
    players[currentPlayer].selectedCard = nil
  end

  if key == "space" then
    if activeSet ~= field then
      players[currentPlayer].selectedCard = activeSet[currentCard]
      selectField()
    elseif activeSet == field then
      if toggleSelection(activeSet[currentCard]) then
        table.insert(currentSelection, activeSet[currentCard])
      end
    end
  end

  if key == "return" then
    local selectedCard = players[currentPlayer].selectedCard

    if selectedCard ~= nil then
      captureCards(selectedCard)
    end
  end

  if key == "x" then
    layCardInField(players[currentPlayer].selectedCard)
  end
end