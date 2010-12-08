require "basic/basiclib"

module Basic
  module Compiler
    extend self

    def varname(string)
      string.downcase.gsub("$","_string")
    end

    def expression(command)
      expression = []
      while token = translate_token(command,expression)
        expression << token
      end
      expression.join("")
    end

    def basic_operator_to_ruby(op)
      case op
      when "="
        "=="
      when "<>"
        "!="
      when "AND"
        "&&"
      when "OR"
        "||"
      else
        op.downcase
      end
    end

    def translate_token(command,expression)
      return nil if command.empty?
      token = command.shift

      if BasicLib::OPERATORS.include?(token)
       basic_operator_to_ruby(token)
      elsif BasicLib::EXPRESSION_TERMINATORS.include?(token)
       command.unshift(token)
       nil
      elsif token =~ /^\d+(\.\d+)?$/
       token
      elsif token[0..0] == "\""
       token
      elsif BasicLib::FUNCTIONS.include?(token)
       "self.#{varname(token)}"
      else
       variable_expression(token,command)
      end
    end
    
    def variable_expression(token,command)
      var = "@"+varname(token)
       if command.first == "("
        var << "["
        out =  expression(index_expression(command))
        var << out
        var << "]"
       end
       var
    end
    
    def index_expression(command)
      out_expression = [command.shift]
      left_brackets = 1
      while left_brackets > 0 && !command.empty?
        token = command.shift
        out_expression << token
        left_brackets += 1 if token == "("
        left_brackets -= 1 if token == ")"
      end
      out_expression
    end

    def nextline(num,segment)
      "return nextline(#{num},#{segment})"
    end

    def x_REM(c,num,segment)
      [nextline(num,segment)]
    end

    def x_STOP(c,num,segment)
      ["raise StopException"]
    end

    def x_CLS(c,num,segment)
      ['system("clear")',nextline(num,segment)]
    end

    def x_RETURN(c,num,segment)
      ["return"]
    end

    def x_GOSUB(c,num,segment)
      # GOSUB 200
      gnum = c.shift
      ["self.gosub(#{gnum})",nextline(num,segment)]
    end

    def x_IF(c,num,segment)
      exp = expression(c)
      c.shift # THEN
      [ "if (#{exp}) then",
          self.compile(c,num,segment),
        "else",
          "return nextline(#{num},#{segment})",
        "end"]
    end

    def x_DIM(c,num,segment)
      var = varname(c.shift) 
      c.shift #(
      size = c.shift
      c.shift #)
      [ "@#{var} = []\n",nextline(num,segment) ]
    end

    def x_INPUT(c,num,segment)
      var = varname(c.shift)
      if var =~ /_string/
        statements <<-END
          @#{var} = self.readline("? ")
          return nextline(#{num},#{segment})
        END
      else
        statements <<-END
          @#{var} = self.readline("? ").to_f 
          return nextline(#{num},#{segment})
        END
      end
    end

    def statements(text)
      text.split(/\n/).map{ |line| line.strip }
    end

    def x_LET(c,num,segment)
      var = variable_expression(c.shift,c)
      c.shift # =
      value = expression(c)
      statements <<-END
        #{var} = (#{value})
        return nextline(#{num},#{segment})
      END
    end

    def x_FOR(c,num,segment)
      # FOR I = 1 TO 10
      var = varname(c.shift)
      c.shift # =
      start = expression(c)
      c.shift # TO
      lend = expression(c)
      statements <<-END
        @#{var} = (#{start})
        @#{var}_end = (#{lend})
        @#{var}_loop_line_no,@#{var}_segment = nextline(#{num},#{segment})
        return nextline(#{num},#{segment})
      END
    end

    def x_NEXT(c,num,segment)
      # NEXT I
      var = varname(c.shift)
      statements <<-END
        @#{var} += 1
        if @#{var} > @#{var}_end
          return nextline(#{num},#{segment})
        else
          return [@#{var}_loop_line_no,@#{var}_segment]
        end
      END
    end

    def x_PRINT(c,num,segment)
      # PRINT "Hello"
      statements = []
      statements << "self.print \"\\n\"" if c.empty?   
      while not c.empty?
        out = expression(c)
        statements << "self.print(#{out})"
        if c.empty?
          statements << "self.print \"\\n\""
        else
          delim = c.shift
          if delim == ","
            statements << "self.print \"\\t\""
          elsif delim == ";"
            break if c.empty?
          end
        end
      end
      statements << "return nextline(#{num},#{segment})"
      statements
    end

    def x_GOTO(c,num,segment)
      # GOTO 20
      number = c.shift
      ["return [#{number},0]"]
    end

    def compile(c,number,segment)
      command,*rest = c
      self.send("x_#{command}".to_sym,rest,number,segment).join("\n")
    end
  end
end
