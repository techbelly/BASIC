require "rubygems"
require "termios"             

CHARACTER_MODE = "termios"    

class Terminal
  
  def initialize(input = $stdin, output = $stdout)
    @input   = input
    @output  = output
  end
  
  def get_line()
    # should probably use readline here...
    @input.gets
  end

  def get_character( input = nil )
    input ||= @input
    old_settings = Termios.getattr(input)

    new_settings                     =  old_settings.dup
    new_settings.c_lflag             &= ~(Termios::ECHO | Termios::ICANON)
    new_settings.c_cc[Termios::VMIN] =  0
    new_settings.c_cc[Termios::VTIME] =  1

    begin
      Termios.setattr(input, Termios::TCSAFLUSH , new_settings)
      i = input.getbyte
      i.nil? ? nil : i.chr
    ensure
      Termios.setattr(input, Termios::TCSAFLUSH, old_settings)
    end
  end
  
  def say(string)
    string = " " unless string
    @output.print string
    @output.flush
  end
  
end

term = Terminal.new
term.get_line
sleep 5
term.say "GO\n"

while true
  term.say(term.get_character)
end