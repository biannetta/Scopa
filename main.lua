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
  
  game = Game()
  game:init(2, 1) 
end

function love.update(dt)
  game:updateMessage(dt)
end

function love.draw()
  love.graphics.setBackgroundColor(0.1, 0.1, 0.15)
  love.graphics.setColor(1, 1, 1)

  -- Display Player Hands
  local playerGrid = {
    { 8, 4 },
    { 2, 4 }
  }

  for i,player in ipairs(game.players) do
    local cardArea = playerGrid[i]
    local pos = grid[cardArea[1]][cardArea[2]]
    
    game:drawPlayerHand(player, pos[1], pos[2])
  end
  
  -- Display Field
  love.graphics.setColor(1, 1, 1)
  game:drawField(grid[5][4][1], grid[5][4][2])

  love.graphics.setColor(1, 1, 1)
  game:drawDeck(grid[5][3][1], grid[5][3][2])

  game:displayMessages(grid[10][5][1], grid[10][5][2])
  
  if game:isPaused() then
    game:printScoreSummary(grid[2][4][1], grid[2][4][2])
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
    end
  end

  if key == "escape" then
    game:togglePause()
  end

  if key == "r" then
    game:init(2)
  end
end