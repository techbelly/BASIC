require "basic/basiclib"
require "basic/runtime"

module Basic
  class StopException < Exception
  end

  class Program
    def self.run()
      @env = {}
      line_no = @lines.keys.min
      return unless line_no
      begin
        b = self.new
        b.gosub(line_no)
      rescue StopException
      end
    end

    def self.env
      @env
    end

    def self.list()
      @lines.sort_by{ |num, _| num }.each do |num, parts|
        print num
        parts.each do |statements|
          spaced = statements.map{ |s|
            s =~ /^[A-Z]{2,}$/ && !FUNCTIONS.include?(s)
          }
          (0...statements.length).each do |i|
            if i == 0 || spaced[i] || spaced[i-1]
              print " "
            end
            print statements[i]
          end
        end
        puts
      end
    end

    def self.generated()
      @generated.keys.sort.each do |k|
        puts @generated[k]
      end
    end

    def self.next(num,segment)
       if @lines[num][segment+1]
         [num,segment+1]
       elsif next_line = @lines.keys.select {|m| m > num }.min
         [next_line,0]
       else
         nil
       end
    end

    def self.clear()
      @lines = {}
      @generated = {}
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

    def self.method_name(num,seg=0)
      method_name = "line_#{num}_#{seg}".to_sym
    end

    def self.remove(num)
      @lines[num].each_with_index do |seg,i|
         remove_method(method_name(num,i))
         @generated.delete([num,seg])
      end
      @lines.delete(num)
    end

    def self.define(num,seg,t,s)
      name = method_name(num,seg)
      method = ["def #{name}",s,"end"].join("\n")
      begin
        eval(method)
        @generated[[num,seg]] = method
        @lines[num] = [] unless @lines[num]
        @lines[num][seg] = t
      rescue SyntaxError
        puts "SYNTAX ERROR in LINE #{num}"
        puts t.join(" ")
      end
    end

    include BasicLib
    include Runtime
  end
end
