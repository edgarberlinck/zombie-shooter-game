function love.load()
  FPS = 60
  math.randomseed(os.time())

  GameSprites = {}
  GameSprites.background = love.graphics.newImage('sprites/background.png')
  GameSprites.bullet = love.graphics.newImage('sprites/bullet.png')
  GameSprites.player = love.graphics.newImage('sprites/player.png')
  GameSprites.zombie = love.graphics.newImage('sprites/zombie.png')

  KeyboardKey = {
    UP = "w",
    DOWN = "s",
    LEFT = "a",
    RIGHT = "d"
  }

  GameState = {
    OnMenu = 1,
    GameOver = 2,
    InGame = 3
  }

  GameManager = {
    elapsedFrames = 0,
    state = GameState.OnMenu,
    score = 0,
    numberOfShoots = 0
  }

  GameManager.player = {
    sprite = GameSprites.player,
    speed = 3 * FPS,

    x = love.graphics.getWidth() / 2,
    y = love.graphics.getHeight() / 2,
    moveRight = function(deltaTime)
      if (GameManager.player.x < love.graphics.getWidth()) then
        GameManager.player.x = GameManager.player.x + GameManager.player.speed * deltaTime
      end
    end,
    moveLeft = function(deltaTime)
      if GameManager.player.x > 0 then
        GameManager.player.x = GameManager.player.x - GameManager.player.speed * deltaTime
      end
    end,
    moveTop = function(deltaTime)
      if GameManager.player.y > 0 then
        GameManager.player.y = GameManager.player.y - GameManager.player.speed * deltaTime
      end
    end,
    moveBotton = function(deltaTime)
      if GameManager.player.y < love.graphics.getHeight() then
        GameManager.player.y = GameManager.player.y + GameManager.player.speed * deltaTime
      end
    end,

    update = function()
      love.graphics.draw(
        GameManager.player.sprite,
        GameManager.player.x,
        GameManager.player.y,
        PlayerMouseAngle(),
        nil,
        nil,
        GameManager.player.sprite:getWidth() / 2,
        GameManager.player.sprite:getHeight() / 2
      )
    end
  }

  -- Enemies
  GameEnemies = {}
  Bullets = {}
end

function love.update(deltaTime)
  if love.keyboard.isDown("space") and GameManager.state ~= GameState.InGame then
    GameManager.state = GameState.InGame
    GameManager.score = 0
    GameManager.numberOfShoots = 0
  end

  if GameManager.state == GameState.InGame then
    if love.keyboard.isDown(KeyboardKey.RIGHT) then
      GameManager.player.moveRight(deltaTime)
    end

    if love.keyboard.isDown(KeyboardKey.LEFT) then
      GameManager.player.moveLeft(deltaTime)
    end

    if love.keyboard.isDown(KeyboardKey.UP) then
      GameManager.player.moveTop(deltaTime)
    end

    if love.keyboard.isDown(KeyboardKey.DOWN) then
      GameManager.player.moveBotton(deltaTime)
    end

    -- Enemy Generation
    if (GameManager.elapsedFrames == 60) then
      SpawnZombie()
      GameManager.elapsedFrames = 0
    else
      GameManager.elapsedFrames = GameManager.elapsedFrames + 1
    end
    -- Enemy movement
    for _, enemy in ipairs(GameEnemies) do
      local enemyMovimentAngle = EnemyPlayerAngle(enemy)
      enemy.x = enemy.x + math.cos(enemyMovimentAngle) * enemy.speed * deltaTime
      enemy.y = enemy.y + math.sin(enemyMovimentAngle) * enemy.speed * deltaTime

      if DistanceBetween(enemy.x, enemy.y, GameManager.player.x, GameManager.player.y) < 30 then
        GameManager.state = GameState.GameOver
        GameEnemies = {}
        Bullets = {}
      end
    end
    --------

    -- Bullet movement
    for _, bullet in ipairs(Bullets) do
      bullet.x = bullet.x + math.cos(bullet.direction) * bullet.speed * deltaTime
      bullet.y = bullet.y + math.sin(bullet.direction) * bullet.speed * deltaTime
    end
    ------

    -- Destoy out-of-bounds bullet
    for i = #Bullets, 1, -1 do -- walking backwards
      local bullet = Bullets[i]
      if bullet.dead or bullet.x < 0 or bullet.y < 0 or bullet.x > love.graphics.getWidth() or bullet.y > love.graphics.getHeight() then
        table.remove(Bullets, i)
      end
    end
    --

    -- Test for colision with bullets
    for i, enemy in ipairs(GameEnemies) do
      for j, bullet in ipairs(Bullets) do
        if DistanceBetween(enemy.x, enemy.y, bullet.x, bullet.y) < 20 then
          enemy.dead = true
          bullet.dead = true
          GameManager.score = GameManager.score + 1
        end
      end
    end

    -- Remove defeated enemies
    for i = #GameEnemies, 1, -1 do
      if (GameEnemies[i].dead) then
        table.remove(GameEnemies, i)
      end
    end
  end
end

function love.draw()
  love.graphics.draw(GameSprites.background, 0, 0)
  love.graphics.printf(
    "Score: " .. GameManager.score,
    0,
    love.graphics.getHeight() - 100,
    love.graphics.getWidth(),
    "center"
  )

  if GameManager.state == GameState.OnMenu then
    love.graphics.setFont(love.graphics.newFont(30))
    love.graphics.printf(
      "Press space to start",
      0,
      50,
      love.graphics.getWidth(),
      "center"
    )
  end
  if GameManager.state == GameState.GameOver then
    love.graphics.setFont(love.graphics.newFont(30))
    love.graphics.printf(
      "You shoot " .. GameManager.numberOfShoots .. " and killed " .. GameManager.score,
      0,
      50,
      love.graphics.getWidth(),
      "center"
    )
    love.graphics.printf(
      GetPlayerGrade(),
      0,
      love.graphics.getHeight() / 2,
      love.graphics.getWidth(),
      "center"
    )
  end

  if GameManager.state == GameState.InGame then
    GameManager.player.update()

    for _, enemy in ipairs(GameEnemies) do
      love.graphics.draw(
        enemy.sprite,
        enemy.x,
        enemy.y,
        EnemyPlayerAngle(enemy),
        nil,
        nil,
        enemy.sprite:getWidth() / 2,
        enemy.sprite:getHeight() / 2)
    end

    for _, bullet in ipairs(Bullets) do
      love.graphics.draw(
        bullet.sprite,
        bullet.x,
        bullet.y,
        nil,
        0.5, -- resize x
        nil,
        bullet.sprite:getWidth() / 2,
        bullet.sprite:getHeight() / 2
      )
    end
  end
end

function love.mousepressed(x, y, button)
  if button == 1 then
    Shoot()
  end
end

function PlayerMouseAngle()
  return math.atan2(
    GameManager.player.y - love.mouse.getY(),
    GameManager.player.x - love.mouse.getX()
  ) + math.pi
end

function DistanceBetween(x1, y1, x2, y2)
  return math.sqrt((x2 - x1) ^ 2 + (y2 - y1) ^ 2)
end

function EnemyPlayerAngle(enemy)
  return math.atan2(
    GameManager.player.y - enemy.y,
    GameManager.player.x - enemy.x
  )
end

function SpawnZombie()
  local zombie = {}

  zombie.sprite = GameSprites.zombie
  zombie.x = 0
  zombie.y = 0
  zombie.speed = math.random(20, 140)
  zombie.dead = false -- My zombies aren't dead, thay are person with the propper rigth to live :)

  -- decide which side the zobie should spawn
  local side = math.random(1, 4)

  if side == 1 then
    zombie.x = -30
    zombie.y = math.random(0, love.graphics.getHeight())
  elseif side == 2 then
    zombie.x = love.graphics.getWidth() + 30
    zombie.y = math.random(0, love.graphics.getHeight())
  elseif side == 3 then
    zombie.x = math.random(0, love.graphics.getWidth())
    zombie.y = -30
  else
    zombie.x = math.random(0, love.graphics.getWidth())
    zombie.y = love.graphics.getHeight() + 30
  end

  table.insert(GameEnemies, zombie)
end

function Shoot()
  local bullet = {}

  bullet.sprite = GameSprites.bullet
  bullet.x = GameManager.player.x
  bullet.y = GameManager.player.y
  bullet.speed = 500
  bullet.direction = PlayerMouseAngle()
  bullet.dead = false

  table.insert(Bullets, bullet)
  GameManager.numberOfShoots = GameManager.numberOfShoots + 1
end

function GetPlayerGrade()
  local difference = GameManager.score / GameManager.numberOfShoots

  if difference == 1 then
    return "You shoot like Bob Lee Swagger"
  elseif difference > 0.7 then
    return "You made a descent job"
  elseif difference >= 0.5 then
    return "For you kill is more important than precision"
  else
    return "You suck more than my gramma"
  end
end
