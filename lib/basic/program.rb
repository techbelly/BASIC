require "basic/basiclib"
require "basic/runtime"

module Basic
  class StopException < Exception
  end

  class Program
    def self.run()
      line_no = @lines.keys.min
      return unless line_no
      begin
        b = self.new
        b.gosub(line_no)
      rescue StopException
      end
    end

    def self.list()
      @lines.sort_by{ |num, _| num }.each do |num, line|

        puts "#{num} #{line.join(" ")}"
      end
    end

    def self.next(num)
       @lines.keys.select {|m| m > num }.min
    end

    def self.clear()
      @lines = {}
    end

    def self.renumber(increment=10)
      old_numbers = @lines.keys.sort
      new_numbers = (1..@lines.length).map{ |v| v * increment.to_i }
      retarget = Hash[*old_numbers.zip(new_numbers).flatten]
      @lines = @lines.inject({}){ |new_lines, (num, parts)|
        new_num = retarget[num]
        (1...parts.length).each do |i|
          if %w[GOTO GOSUB].include?(parts[i-1])
            parts[i] = retarget[parts[i].to_i].to_s
          end
        end
        new_lines.merge(new_num => parts)
      }
    end

    def self.method_name(num)
      method_name = "line_#{num}".to_sym
    end

    def self.remove(num)
      @lines.delete(num)
      remove_method(method_name(num))
    end

    def self.define(num,t,s)
      name = method_name(num)
      method = "def #{name}\n#{s}\nend\n"
      begin
        eval(method)
        @lines[num] = t
      rescue SyntaxError
        puts "SYNTAX ERROR in LINE #{num}"
        puts t.join(" ")
      end
    end

    include BasicLib
    include Runtime
  end
end
