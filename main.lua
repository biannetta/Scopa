function love.load()
  Card = require "card"
  Game = require "game"

  local h = love.graphics.getHeight()
  local w = love.graphics.getWidth()
  local max = 12
  
  grid = {}

  for i=1,max do
    grid[i] = {}
    
    for j=1,max do
      local x = (w/max) * (j-1)
      local y = (h/max) * (i-1)
      grid[i][j] = { x, y }
    end
  end
  
  toastMessages = nil
  toastLength = 5
  
  function dealCards(hand, noCards, deck)
    for j=1,noCards do
      table.insert(hand, deck:dealCard())
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

  function addCards(set, cards)
    for i,card in ipairs(cards) do
      set[#set + i] = card
    end
  end

  function captureCards(targetCard, selection)
    if targetCard.value ~= summarizeSelection(selection) then
      return false
    end

    if isCardInSet(targetCard, game.field, 1) and #selection ~= 1 then
      return false
    end
      
    addCards(game:activePlayer().capturedCards, selection)
    table.insert(game:activePlayer().capturedCards, game:activePlayer().selectedCard)

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
    game = Game(2) 
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
  for i=1,#grid do
    for j=1,#grid[i] do
      love.graphics.points(grid[i][j][1], grid[i][j][2])
    end
  end

  local function drawHand(hand, selection, row, col, active)
    for j,card in ipairs(hand) do
      local isHighlighted = (active and j == game.cursor)
      local isSelected = isCardInSet(card, selection)
      local pos = grid[row][col+j]
      card:draw(pos[1], pos[2], isHighlighted, isSelected)
    end 
  end

  love.graphics.setBackgroundColor(0.1, 0.1, 0.15)
  love.graphics.setColor(1, 1, 1)

  -- Display Player Hands
  local playerGrid = {
    grid[2],
    grid[8]
  }

  for i,player in ipairs(game.players) do
    local cardArea = playerGrid[i][3]
    local activeHand = game:activePlayer() == player and game.state == "HAND"
    
    love.graphics.setColor(1, 1, 1)
    love.graphics.print(player.name..' Hand '..'Total Captured '..player:totalCaptured(), cardArea[1], cardArea[2] - 25)
    drawHand(player.hand, { player.selectedCard }, 2, 2, activeHand)
  end
  
  -- Display Field
  love.graphics.setColor(1, 1, 1)
  drawHand(game.field, game.currentSelection, 5, 2, (game.state == "FIELD"))

  --[[
  love.graphics.setColor(1, 1, 1)
  love.graphics.print('Current Selected Value: '..summarizeSelection(game.currentSelection), 10, 85 + (Card.height * 2))
  love.graphics.print('Cards Remaining: '..game.deck:count(), 10, 110 + (Card.height * 2))
  love.graphics.print('User arrow keys and press "space" to select a card. Press "enter" to capture cards, press "x" to lay selected card on table', 10, 135 + (Card.height * 2))
  ]]

  if toastMessages ~= nil then
    love.graphics.print(toastMessages, 10, 600)
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