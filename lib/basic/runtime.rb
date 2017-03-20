require "termios"

module Basic
  module Runtime

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

    class BasicArray
      def initialize(extents,default)
        @hash = Hash.new(default)
        @extents = extents
      end

      def [](key)
        @hash[key]
      end

      def []=(key,value)
        @hash[key]= value
      end

      def dimensions
        @extents.size
      end
    end

    def create_array(extents)
      return BasicArray.new(extents,Value.new(0))
    end

    def create_string_array(extents)
      return BasicArray.new(extents,Value.new(""))
    end

    def funcname(string)
      string.downcase.gsub("$","_string")
    end

    def basic_operator_to_ruby(op)
      {
        "+" =>   "plus",
        "-" =>   "minus",
        "*" =>   "times",
        "/" =>   "divided_by",
        "OR" =>  "logic_or",
        "AND" => "logic_and",
        "=" =>   "equal",
        "<>" =>  "not_equal",
        "<=" =>  "lte",
        ">=" =>  "gte",
        "<" =>   "lt",
        ">" =>   "gt"
      }[op]
    end

    class Value
      def initialize(value)
        @value = value
      end

      def value
        @value
      end

      def plus(other)
        @value+other.value
      end

      def minus(other)
        @value-other.value
      end

      def times(other)
        @value*other.value
      end

      def divided_by(other)
        @value/other.value
      end

      def wrap(value)
        value ? 1 : 0
      end

      def to_b
        !(@value == 0)
      end

      def logic_or(other)
        wrap(self.to_b || other.to_b)
      end

      def logic_and(other)
        wrap(self.to_b && other.to_b)
      end

      def equal(other)
        wrap(@value == other.value)
      end

      def not_equal(other)
        wrap(@value != other.value)
      end

      def lte(other)
        wrap(@value <= other.value)
      end

      def gte(other)
        wrap(@value >= other.value)
      end

      def lt(other)
        wrap(@value < other.value)
      end

      def gt(other)
        wrap(@value > other.value)
      end

      def to_s
        @value.to_s
      end

      def inspect
        to_s
      end

      def hash
        @value.hash
      end

    end

    def evaluate(tokens)
      stack = []
      tokens.each do |type,token|
        case type
          when :operator
            operator = basic_operator_to_ruby(token)
            addend, augend = stack.pop, stack.pop
            stack.push Value.new(augend.send(operator.to_sym,addend))
          when :function
            funcname = funcname(token)
            arity = method(funcname).arity
            args = []
            arity.times do
              args.unshift stack.pop
            end
            stack.push Value.new(self.send(funcname.to_sym,*args.map{|a| a.value}))
          when :array_ref
            array = self.env[token]
            dimensions = array.dimensions
            args = []
            dimensions.times do
              args.unshift stack.pop
            end
            stack.push array[args.map {|s| s.value}]
          when :variable
            stack.push self.env[token]
          else
            stack.push Value.new(token)
        end
      end
      stack.pop
    end

    def cols
      @cols || 0
    end

    def print_tab
      print("\t")
    end

    def print_newline
      print("\n")
    end

    def maxcol
      80
    end

    def print(string)
      @cols ||= 0
      string.to_s.each_char do |c|
        $stdout.print c
        if c == "\n"
          @cols = 0
        else
          @cols = @cols + 1
        end
        if @cols > maxcol
          $stdout.print "\n"
          @cols = 0
        end
      end
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
