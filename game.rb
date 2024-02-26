require 'gosu'

class GameWindow < Gosu::Window
  def initialize
    super(800, 600, false)
    self.caption = 'Boss Fight Game with Shooting'

    @player = Player.new
    @boss = Boss.new
    @projectiles = []
    @projectile_cooldown = 0
    @game_over = false
    @font = Gosu.default_font_name
    @font_size = 50
  end

  def update
    return if @game_over

    @player.move_up if Gosu.button_down?(Gosu::KB_UP)
    @player.move_down if Gosu.button_down?(Gosu::KB_DOWN)

    @boss.move
    update_projectiles
    check_player_collision

    if @projectile_cooldown.zero?
      shoot_projectile(@boss.x, @boss.y + @boss.height / 2, @player.x + @player.width / 2, @player.y + @player.height / 2)
      @projectile_cooldown = 60
    else
      @projectile_cooldown -= 1
    end

    check_game_over
  end

  def draw
    @player.draw
    @boss.draw
    draw_projectiles

    if @game_over
      draw_game_over
      draw_buttons
    end
  end

  def draw_game_over
    message = 'Game Over'
    x = (self.width - Gosu.measure_text(message, @font, @font_size)) / 2
    y = self.height / 2 - @font_size / 2
    Gosu.draw_text(message, x, y, 1, 1, 1, Gosu::Color::RED)
  end

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

  def draw_projectiles
    @projectiles.each(&:draw)
  end

  def button_down(id)
    case id
    when Gosu::MS_LEFT
      if @game_over
        check_button_click
      end
    end
  end

  def check_button_click
    mouse_x = mouse_x
    mouse_y = mouse_y

    restart_button_x = self.width / 4 - 50
    restart_button_y = self.height / 2 + 50
    restart_button_width = 100
    restart_button_height = 40

    exit_button_x = self.width * 3 / 4 - 50
    exit_button_y = self.height / 2 + 50
    exit_button_width = 100
    exit_button_height = 40

    if mouse_x >= restart_button_x && mouse_x <= restart_button_x + restart_button_width &&
       mouse_y >= restart_button_y && mouse_y <= restart_button_y + restart_button_height
      restart_game
    elsif mouse_x >= exit_button_x && mouse_x <= exit_button_x + exit_button_width &&
          mouse_y >= exit_button_y && mouse_y <= exit_button_y + exit_button_height
      close
    end
  end

  def restart_game
    @game_over = false
    @player.reset_game
  end

  def update_projectiles
    @projectiles.each(&:move)
    @projectiles.reject! { |projectile| projectile.x > self.width }
  end

  def shoot_projectile(start_x, start_y, target_x, target_y)
    dx = target_x - start_x
    dy = target_y - start_y
    magnitude = Math.sqrt(dx**2 + dy**2)
    normalized_dx = dx / magnitude
    normalized_dy = dy / magnitude

    projectile = Projectile.new(start_x, start_y, normalized_dx, normalized_dy)
    @projectiles.push(projectile)
  end

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

  def check_game_over
    if @player.hp <= 0
      @game_over = true
    end
  end
end

class Player
  attr_reader :x, :y, :width, :height, :hp

  def initialize
    @x = 50
    @y = 300
    @width = 50
    @height = 50
    @hp = 100
  end

  def move_up
    @y -= 5 if @y > 0
  end

  def move_down
    @y += 5 if @y < 550
  end

  def draw
    Gosu.draw_rect(@x, @y, @width, @height, Gosu::Color::BLUE)
  end

  def take_damage
    @hp -= 10
  end

  def reset_game
    @y = 300
    @hp = 100
  end
end

class Boss
  attr_reader :x, :y, :width, :height, :speed

  def initialize
    @x = 700
    @y = 300
    @width = 80
    @height = 80
    @speed = 2
    @cooldown = 0
  end

  def move
    @y += @speed
    @speed = -@speed if @y <= 0 || @y + @height >= 600
    @cooldown = [@cooldown - 1, 0].max
  end

  def draw
    Gosu.draw_rect(@x, @y, @width, @height, Gosu::Color::RED)
  end

  def reset
    @y = 300
    @cooldown = 0
  end

  def can_shoot?
    @cooldown.zero?
  end

  def shoot
    @cooldown = 60
  end
end

class Projectile
  attr_reader :x, :y, :width, :height, :speed, :dx, :dy

  def initialize(start_x, start_y, dx, dy)
    @x = start_x
    @y = start_y
    @width = 20
    @height = 5
    @speed = 8
    @dx = dx
    @dy = dy
  end

  def move
    @x += @speed * @dx
    @y += @speed * @dy
  end

  def draw
    Gosu.draw_rect(@x, @y, @width, @height, Gosu::Color::YELLOW)
  end
end

window = GameWindow.new
window.show