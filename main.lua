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
  
  game = Game()
  game:init(2) 
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
  local function drawText(text, row, col)
    local pos = grid[row][col]
    love.graphics.print(text, pos[1], pos[2])
  end

  love.graphics.setBackgroundColor(0.1, 0.1, 0.15)
  love.graphics.setColor(1, 1, 1)

  -- Display Player Hands
  local playerGrid = {
    { 2, 4 },
    { 8, 4 }
  }

  for i,player in ipairs(game.players) do
    local cardArea = playerGrid[i]
    local pos = grid[cardArea[1]][cardArea[2]]
    
    love.graphics.setColor(1, 1, 1)
    drawText(player.name..' Hand '..'Total Captured '..player:totalCaptured(), cardArea[1] -1, cardArea[2])
    game:drawPlayerHand(player, pos[1], pos[2])
  end
  
  -- Display Field
  love.graphics.setColor(1, 1, 1)
  game:drawField(grid[5][4][1], grid[5][4][2])

  love.graphics.setColor(1, 1, 1)
  drawText('Current Selected Value: '..game:sumOfSet(game.currentSelection), 4, 4)
  --love.graphics.print('Cards Remaining: '..game.deck:count(), 10, 110 + (Card.height * 2))
  --love.graphics.print('User arrow keys and press "space" to select a card. Press "enter" to capture cards, press "x" to lay selected card on table', 10, 135 + (Card.height * 2))

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

  if key == "u" then
    game:selectHand()
  end

  if key == "space" then
    game:selectCard()
  end

  if key == "return" then
    if game:isValidMove() then
      game:captureCards()
      game:nextTurn()
    else
      toastMessages = "Cannot capture selected cards"
    end
  end
end