Player = Class{}

require 'Animation'

local MOVE_SPEED = 80
local JUMP_VELOCITY = 400

function Player:init(map)
  self.width = 16
  self.height = 20

  self.map = map

  self.x = map.tileWidth * 10
  self.y = map.tileHeight * (map.mapHeight / 2 - 1) - self.height

  self.dx = 0
  self.dy = 0

  self.texture = love.graphics.newImage('blue_alien.png')
  self.frames = generateQuads(self.texture, 16, 20)

  self.state = 'idle'
  self.direction = 'right'

  gameState = 'start'

  self.sounds = {
    ['jump'] = love.audio.newSource('jump.wav', 'static'),
    ['hit'] = love.audio.newSource('hit.wav', 'static'),
    ['coin'] = love.audio.newSource('coin.wav', 'static')
  }

  self.animations = {
    ['idle'] = Animation {
      texture = self.texture,
      frames = {
        self.frames[1]
      },
      interval = 1
    },
    ['walking'] = Animation {
      texture = self.texture,
      frames = {
        self.frames[9], self.frames[10], self.frames[11]
      },
      interval = 0.15
    },
    ['jumping'] = Animation {
      texture = self.texture,
      frames = {
        self.frames[3]
      },
      interval = 1
    }
  }

  self.animation = self.animations['idle']

  self.behaviors = {
    ['idle'] = function(dt)
      if love.keyboard.wasPressed('space') then
        self.dy = -JUMP_VELOCITY
        self.state = 'jumping'
        self.animation = self.animations['jumping']
        self.sounds['jump']:play()
      elseif love.keyboard.isDown('a') then
        self.direction = 'left'
        self.dx = -MOVE_SPEED
        self.state = 'walking'
        self.animations['walking']:restart()
        self.animation = self.animations['walking']
      elseif love.keyboard.isDown('d') then
        self.direction = 'right'
        self.dx = MOVE_SPEED
        self.state = 'walking'
        self.animations['walking']:restart()
        self.animation = self.animations['walking']
      else
        self.animation = self.animations['idle']
      end
    end,
    ['walking'] = function(dt)
      if love.keyboard.wasPressed('space') then
        self.dy = -JUMP_VELOCITY
        self.state = 'jumping'
        self.animation = self.animations['jumping']
        self.sounds['jump']:play()
      elseif love.keyboard.isDown('a') then
        self.dx = -MOVE_SPEED
        self.animation = self.animations['walking']
        self.direction = 'left'
      elseif love.keyboard.isDown('d') then
        self.dx = MOVE_SPEED
        self.animation = self.animations['walking']
        self.direction = 'right'
      else
        self.dx = 0
        self.animation = self.animations['idle']
      end

      self:checkRightCollision()
      self:checkLeftCollision()

      if not self.map:collides(self.map:tileAt(self.x, self.y + self.height)) and
          not self.map:collides(self.map:tileAt(self.x + self.width - 1, self.y + self.height)) then

          self.state = 'jumping'
          self.animation = self.animations['jumping']
      end
    end,
    ['jumping'] = function(dt)
      if love.keyboard.isDown('a') then
        self.direction = 'left'
        self.dx = -MOVE_SPEED
      else if love.keyboard.isDown('d') then
        self.direction = 'right'
        self.dx = MOVE_SPEED
      else
        self.dx = 0
      end
      end

      self.dy = self.dy + self.map.gravity

      if self.map:collides(self.map:tileAt(self.x, self.y + self.height)) or
          self.map:collides(self.map:tileAt(self.x + self.width - 1, self.y + self.height)) then

          self.y = (self.map:tileAt(self.x, self.y + self.height).y - 1) * self.map.tileHeight - self.height
          self.dy = 0
          self.state = 'idle'
          self.animation = self.animations['idle']
      end
      self:checkRightCollision()
      self:checkLeftCollision()
    end
  }
end

function Player:update(dt)
  self.behaviors[self.state](dt)
  self.animation:update(dt)
  self.currentFrame = self.animation:getCurrentFrame()
  self.x = self.x + self.dx * dt
  self.y = self.y + self.dy * dt

  if self.dy < 0 then
    if self.map:tileAt(self.x, self.y).id ~= TILE_EMPTY or
        self.map:tileAt(self.x + self.width - 1, self.y).id ~= TILE_EMPTY then

        self.dy = 0
        local playCoin = false
        local playHit = false
      if self.map:tileAt(self.x, self.y).id == JUMP_BLOCK then
          self.map:setTile(math.floor(self.x / self.map.tileWidth) + 1,
            math.floor(self.y / self.map.tileHeight) + 1, JUMP_BLOCK_HIT)
          playCoin = true
      end
      if self.map:tileAt(self.x + self.width - 1, self.y).id == JUMP_BLOCK then
          self.map:setTile(math.floor((self.x + self.width - 1) / self.map.tileWidth) + 1,
            math.floor(self.y / self.map.tileHeight) + 1, JUMP_BLOCK_HIT)
          playCoin = true
      else
        playHit = true
      end

      if playCoin then
        self.sounds['coin']:play()
      elseif playHit then
        self.sounds['hit']:play()
      end
    end
  end
end

function Player:checkLeftCollision()
  if self.dx < 0 then
    if self.map:collides(self.map:tileAt(self.x - 1, self.y)) or
        self.map:collides(self.map:tileAt(self.x - 1, self.y + self.height - 1)) then

        self.dx = 0
        self.x = self.map:tileAt(self.x - 1, self.y).x * self.map.tileWidth
    end
  end
end

function Player:checkRightCollision()
  if self.dx > 0 then
    if self.map:collides(self.map:tileAt(self.x + self.width, self.y)) or
        self.map:collides(self.map:tileAt(self.x + self.width, self.y + self.height - 1)) then

        self.dx = 0
        self.x = (self.map:tileAt(self.x + self.width, self.y).x - 1) * self.map.tileWidth - self.width
    end
  end
end

function Player:render()
  local scaleX

  if self.direction == 'right' then
    scaleX = 1
  else
    scaleX = -1
  end

  love.graphics.draw(self.texture, self.animation:getCurrentFrame(),
    math.floor(self.x + self.width / 2), math.floor(self.y + self.height / 2),
      0, scaleX, 1,
      self.width / 2, self.height / 2)
end
