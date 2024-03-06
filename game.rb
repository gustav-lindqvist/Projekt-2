require 'gosu'

class GameWindow < Gosu::Window
  def initialize
    super(800, 600, false) # Create a window with dimensions 800x600
    self.caption = 'Boss Fight Game with Shooting' # Set the window title

    # Initialize game objects
    @player = Player.new
    @boss = Boss.new
    @projectiles = []
    @projectile_cooldown = 0
    @game_over = false
    @font = Gosu.default_font_name
    @font_size = 50
  end

  def update
    return if @game_over # If game over, stop updating

    # Player movement based on keyboard input
    @player.move_up if Gosu.button_down?(Gosu::KB_UP)
    @player.move_down if Gosu.button_down?(Gosu::KB_DOWN)

    # Boss movement and projectile management
    @boss.move
    update_projectiles
    check_player_collision
    check_boss_collision

    # Player and boss shooting cooldowns
    @player.shoot(@projectiles) if Gosu.button_down?(Gosu::KB_SPACE) && @projectile_cooldown.zero?
    @boss.shoot(@projectiles) if @boss.can_shoot?

    # Update projectile cooldown
    if @projectile_cooldown.zero?
      @projectile_cooldown = 40
    else
      @projectile_cooldown -= 1
    end

    # Check for game over condition
    check_game_over
  end

  def draw
    # Draw game objects
    @player.draw
    @boss.draw
    draw_projectiles

    # Draw game over message and buttons if game over
    if @game_over
      draw_game_over
      draw_buttons
    end
  end

  # Draw game over message
  def draw_game_over
    message = 'Game Over'
    x = (self.width - Gosu.measure_text(message, @font, @font_size)) / 2
    y = self.height / 2 - @font_size / 2
    Gosu.draw_text(message, x, y, 1, 1, 1, Gosu::Color::RED)
  end

  # Draw buttons for restart and exit
  def draw_buttons
    restart_button_x = self.width / 4 - 50
    restart_button_y = self.height / 2 + 50
    Gosu.draw_rect(restart_button_x, restart_button_y, 100, 40, Gosu::Color::GREEN)

    exit_button_x = self.width * 3 / 4 - 50
    exit_button_y = self.height / 2 + 50
    Gosu.draw_rect(exit_button_x, exit_button_y, 100, 40, Gosu::Color::RED)

    Gosu.draw_text('Restart', restart_button_x + 20, restart_button_y + 10, 1, 1, 1, Gosu::Color::BLACK)
    Gosu.draw_text('Exit', exit_button_x + 35, exit_button_y + 10, 1, 1, 1, Gosu::Color::BLACK)
  end

  # Draw projectiles
  def draw_projectiles
    @projectiles.each(&:draw)
  end

  # Handle mouse button clicks
  def button_down(id)
    case id
    when Gosu::MS_LEFT
      if @game_over
        check_button_click
      end
    end
  end

  # Check if mouse clicks hit buttons
  def check_button_click
    mouse_x = self.mouse_x
    mouse_y = self.mouse_y

    restart_button_x = self.width / 4 - 50
    restart_button_y = self.height / 2 + 50
    restart_button_width = 100
    restart_button_height = 40

    exit_button_x = self.width * 3 / 4 - 50
    exit_button_y = self.height / 2 + 50
    exit_button_width = 100
    exit_button_height = 40

    # Check if mouse click is within button boundaries
    if mouse_x >= restart_button_x && mouse_x <= restart_button_x + restart_button_width &&
       mouse_y >= restart_button_y && mouse_y <= restart_button_y + restart_button_height
      restart_game
    elsif mouse_x >= exit_button_x && mouse_x <= exit_button_x + exit_button_width &&
          mouse_y >= exit_button_y && mouse_y <= exit_button_y + exit_button_height
      close
    end
  end

  # Restart the game
  def restart_game
    @game_over = false
    @player.reset_game
    @boss.reset
  end

  # Update projectile positions
  def update_projectiles
    @projectiles.each(&:move)
    @projectiles.reject! { |projectile| projectile.x > self.width }
  end

  # Check for collisions with player
  def check_player_collision
    return if @game_over

    @projectiles.each do |projectile|
      if (
        @player.x < projectile.x + projectile.width &&
        @player.x + @player.width > projectile.x &&
        @player.y < projectile.y + projectile.height &&
        @player.y + @player.height > projectile.y
      )
        @player.take_damage
        @projectiles.delete(projectile)
      end
    end
  end

  # Check for collisions with boss
  def check_boss_collision
    return if @game_over

    @projectiles.each do |projectile|
      if (
        @boss.x < projectile.x + projectile.width &&
        @boss.x + @boss.width > projectile.x &&
        @boss.y < projectile.y + projectile.height &&
        @boss.y + @boss.height > projectile.y &&
        projectile.source == :player  # Check if the projectile is from the player
      )
        @boss.take_damage
        @projectiles.delete(projectile)
      end
    end
  end

  # Check for game over condition
  def check_game_over
    if @player.hp <= 0 || @boss.hp <= 0
      @game_over = true
    end
  end
end

# Player class
class Player
  attr_reader :x, :y, :width, :height, :hp

  def initialize
    @x = 50
    @y = 300
    @width = 50
    @height = 50
    @hp = 30 # Player's initial health points
  end

  # Move player up
  def move_up
    @y -= 5 if @y > 0
  end

  # Move player down
  def move_down
    @y += 5 if @y < 550
  end

  # Draw the player
  def draw
    player_image = Gosu::Image.new('img/cartoonship_blue.png')
    player_image.draw(@x-10, @y, 1, 0.1,0.1)  
  end

  # Player shoots a projectile
  def shoot(projectiles)
    dx = 1 
    dy = 0 
    projectile = Projectile.new(@x + @width, @y + @height / 2, dx, dy, :player)  # Pass :player as the source
    projectiles.push(projectile)
  end

  # Reduce player's health when taking damage
  def take_damage
    @hp -= 10
  end

  # Reset player's position and health
  def reset_game
    @y = 300
    @hp = 30
  end
end

# Boss class
class Boss
  attr_reader :x, :y, :width, :height, :speed, :hp

  def initialize
    @x = 700
    @y = 300
    @width = 80
    @height = 80
    @speed = 2
    @cooldown = 0
    @hp = 200 # Boss's initial health points
  end

  # Move the boss up and down
  def move
    @y += @speed
    @speed = -@speed if @y <= 0 || @y + @height >= 600
    @cooldown = [@cooldown - 1, 0].max
  end

  # Draw the boss
  def draw
    player_image = Gosu::Image.new('img/boss_spaceship.png')
    player_image.draw(@x-50, @y-40, 1, 0.3,0.3) 
  end

  # Reset boss's position and cooldown
  def reset
    @y = 300
    @cooldown = 0
    @hp = 200
  end

  # Check if boss can shoot
  def can_shoot?
    @cooldown.zero?
  end

  # Boss shoots a projectile
  def shoot(projectiles)
    dx = -1  
    dy = 0  
    projectile = Projectile.new(@x, @y + @height / 2, dx, dy, :boss)  # Pass :boss as the source
    projectiles.push(projectile)
    @cooldown = 30
  end

  # Reduce boss's health when taking damage
  def take_damage
    @hp -= 10
  end
end

# Projectile class
class Projectile
  attr_reader :x, :y, :width, :height, :speed, :dx, :dy, :source

  def initialize(start_x, start_y, dx, dy, source)
    @x = start_x
    @y = start_y
    @width = 20
    @height = 5
    @speed = 8
    @dx = dx
    @dy = dy
    @source = source  # Store the source of the projectile
  end

  # Move the projectile
  def move
    @x += @speed * @dx
    @y += @speed * @dy
  end

  # Draw the projectile
  def draw
    Gosu.draw_rect(@x, @y, @width, @height, Gosu::Color::YELLOW)
  end
end

# Create and show the game window
window = GameWindow.new
window.show
