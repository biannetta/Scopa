function love.load()
  -- variable inits
  deck = {}
  suits = { 'C', 'D', 'S', 'B' }
  ranks = { '1','2','3','4','5','6','7','J','Q','K' }
  
  cardHeight = 160
  cardWidth = 120
  cardCorner = 10  
  
  -- initialize the deck
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

  -- shuffle the deck
  for i=#deck,1,-1 do
    local j = love.math.random(i)
    local temp = deck[i]
    deck[i] = deck[j]
    deck[j] = temp
  end
  
  function dealCards(hand, noCards)
    for j=1,noCards do
      table.insert(hand, table.remove(deck,1))
    end 
  end

  function dealPlayers(players)
    for i=1,#players do
      dealCards(players[i],3)      
    end
  end

  function startGame()
    playerHand = {}
    opponentHand = {}
    tableHand = {}
    
    dealPlayers({playerHand, opponentHand})
    dealCards(tableHand, 4)

    currentHand = playerHand
    currentCard = 1
  end

  startGame()

end

function love.draw()
  local function drawCard(text, xPos, yPos, selected)
    
    local textOffsetX = xPos + 5
    local textOffsetY = yPos + 5
    
    if selected then
      love.graphics.setColor(1, 1, 0, 0.3)
      love.graphics.rectangle("fill", xPos - 5, yPos - 5, cardWidth + 10, cardHeight + 10, cardCorner)

      love.graphics.setColor(1, 1, 0)
      love.graphics.setLineWidth(3)
      love.graphics.rectangle("line", xPos - 5, yPos - 5, cardWidth + 10, cardHeight + 10, cardCorner)
    end

    love.graphics.setColor(0.2, 0.5, 0.9)
    love.graphics.rectangle('fill', xPos, yPos, cardWidth, cardHeight, cardCorner)
    
    love.graphics.setColor(0, 0, 0)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", xPos, yPos, cardWidth, cardHeight, cardCorner)

    love.graphics.setColor(1, 1, 1)
    love.graphics.print(text, textOffsetX, textOffsetY)
  end

  love.graphics.setBackgroundColor(0.1, 0.1, 0.15)

  love.graphics.setColor(1, 1, 1)
  love.graphics.print('Player Hand:', 10, 10)
  
  for i,card in ipairs(playerHand) do
    local selected = playerHand == currentHand and i == currentCard
    drawCard(card:toString(), 10 + (cardWidth + 10) * (i - 1), 35, selected)
  end
  
  love.graphics.setColor(1, 1, 1)
  love.graphics.print('Opponent Hand:',10, 50 + cardHeight)
  
  for i,card in ipairs(opponentHand) do
    local selected = opponentHand == currentHand and i == currentCard
    drawCard(card:toString(), 10 + (cardWidth + 10) * (i - 1), 75 + cardHeight, selected)
  end
  
  love.graphics.setColor(1, 1, 1)
  love.graphics.print('Field:', 10, 90 + (cardHeight * 2))
  for i,card in ipairs(tableHand) do
    local selected = tableHand == currentHand and i == currentCard
    drawCard(card:toString(), 10 + (cardWidth + 10) * (i - 1), 110 + (cardHeight * 2), selected)
  end
  
  love.graphics.setColor(1, 1, 1)
  love.graphics.print('Cards Remaining: '..#deck, 10, 110 + (cardHeight * 3))
  love.graphics.print('User arrow keys and press "space" to select a card. Press "r" to re-shuffle', 10, 135 + (cardHeight * 3))
end

function love.keypressed(key)
  if key == "r" and #deck >= 6 then
    playerHand = {}
    opponentHand = {}
    dealCards({playerHand, opponentHand})
  end

  if key == "j" or key == "left" then
    currentCard = currentCard - 1
    if currentCard < 1  then
      currentCard = #currentHand
    end
  end
  
  if key == "k" or key == "right" then
    currentCard = currentCard + 1
    if currentCard > #currentHand then
      currentCard = 1
    end
  end

  if key == "space" then
    print(currentHand[currentCard].value)
    currentHand = tableHand
  end
end