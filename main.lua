push = require 'push'
Class = require 'class'

require 'Util'
require 'Map'

WINDOW_WIDTH = 1280
WINDOW_HEIGHT = 720

VIRTUAL_WIDTH = 432
VIRTUAL_HEIGHT = 243

function love.load()

  math.randomseed(os.time())

  map = Map()

  love.graphics.setDefaultFilter('nearest', 'nearest')

  love.graphics.setFont(love.graphics.newFont('font.ttf', 8))

  push:setupScreen(VIRTUAL_WIDTH, VIRTUAL_HEIGHT, WINDOW_WIDTH, WINDOW_HEIGHT, {
    fullscreen = false,
    resizable = false,
    vsync = true
  })

  love.keyboard.keysPressed = {}
end

function love.resize(w, h)
  push:resize(w, h)
end

function love.keypressed(key)
  if key == 'escape' then
    love.event.quit()
  end
  love.keyboard.keysPressed[key] = true
end

function love.keyboard.wasPressed(key)
  return love.keyboard.keysPressed[key]
end

function love.update(dt)
  map:update(dt)

  love.keyboard.keysPressed = {}
end

function love.draw()
  love.graphics.clear(108 / 255, 140 / 255, 255 / 255, 255 / 255)
  push:apply('start')
  love.graphics.translate(math.floor(-map.camX + 0.5), math.floor(-map.camY + 0.5))
  map:render()
  push:apply('end')
end
