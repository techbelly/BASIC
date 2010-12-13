require "termios"             

module Basic
  module Runtime
    
    extend self
    
    # This is based on some code that I found in the 
    # highrise library: http://highline.rubyforge.org/
    def getbyte(wait_time=nil)      
      input = $stdin
      old_settings = Termios.getattr(input)
      new_settings  =  old_settings.dup
      new_settings.c_lflag &= ~(Termios::ECHO | Termios::ICANON)
      
      if wait_time
        wait_time = [wait_time,100].max
        new_settings.c_cc[Termios::VMIN] =  0
        new_settings.c_cc[Termios::VTIME] =  (wait_time/10.0)
      else
        new_settings.c_cc[Termios::VMIN] =  1
      end

      begin
        Termios.setattr(input, Termios::TCSAFLUSH , new_settings)
        input.getbyte
      ensure
        Termios.setattr(input, Termios::TCSAFLUSH, old_settings)
      end
    end
    
    def create_array(dimensions)
      return {}
    end
    
    def print(string)
      $stdout.print string
      $stdout.flush
    end
        
    def gosub(line_no,segment=0)
      while line_no
        method_name = self.class.method_name(line_no,segment)
        line_no,segment = self.send(method_name)
      end
    end

    def readline(prompt)
      return Readline.readline(prompt)
    end

    def env
      self.class.env
    end

    def nextline(num,segment)
      self.class.next(num,segment)
    end
  end
end
