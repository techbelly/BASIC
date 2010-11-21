module Basic
  module Compiler
    extend self

    def varname(string)
      string.downcase.gsub("$","_string")
    end

    def expression(command)
      expression = []
      command = command.dup
      while token = translate_token(command,expression)
        expression << token
      end
      [command,expression.join("")]
    end

    def translate_token(command,expression)
      return nil if command.empty?
      token = command.shift
      operators = ["+","-","*","/","=","<",">","(",")","OR","AND"]
      expression_terminators = [",",":",";","THEN","TO"]

      # TODO: SHOULD GENERATE THIS FROM BasicLib
      functions = ["RND","INT","CHR$","INKEY$","ABS","VAL","ASC","SGN","SQR","SIN","ATN"]

      if operators.include?(token)
       token == "=" ? "==" : token.downcase
      elsif expression_terminators.include?(token)
       command.unshift(token)
       nil
      elsif token =~ /\d+/
       token
      elsif token[0..0] == "\""
       token
      elsif functions.include?(token)
       "self.#{varname(token)}"
      else
       "@"+varname(token)
      end
    end

    def nextline(num)
      "return nextline(#{num})"
    end

    def x_REM(c,num)
      [nextline(num)]
    end

    def x_STOP(c,num)
      ["raise StopException"]
    end

    def x_CLS(c,num)
      ['system("clear")',nextline(num)]
    end

    def x_RETURN(c,num)
      ["return"]
    end

    def x_GOSUB(c,num)
      # GOSUB 200
      gnum = c.shift
      ["self.gosub(#{gnum})",nextline(num)]
    end

    def x_IF(c,num)
      c,exp = expression(c)
      c.shift # THEN
      [ "if (#{exp}) then",
          self.compile(c,num),
        "else",
          "return nextline(#{num})",
        "end"]
    end

    def x_INPUT(c,num)
      var = varname(c.shift)
      if var =~ /_string/
        statements <<-END
          @#{var} = self.readline("? ")
          return nextline(#{num})
        END
      else
        statements <<-END
          @#{var} = self.readline("? ").to_i
          return nextline(#{num})
        END
      end
    end

    def statements(text)
      text.split(/\n/).map{ |line| line.strip }
    end

    def x_LET(c,num)
      var = varname(c.shift)
      c.shift # =
      c,value = expression(c)
      statements <<-END
        @#{var} = (#{value})
        return nextline(#{num})
      END
    end

    def x_FOR(c,num)
      # FOR I = 1 TO 10
      var = varname(c.shift)
      c.shift # =
      c,start = expression(c)
      c.shift # TO
      c,lend = expression(c)
      statements <<-END
        @#{var} = (#{start})
        @#{var}_end = (#{lend})
        @#{var}_loop_line_no = nextline(#{num})
        return nextline(#{num})
      END
    end

    def x_NEXT(c,num)
      # NEXT I
      var = varname(c.shift)
      statements <<-END
        @#{var} += 1
        if @#{var} > @#{var}_end
          return nextline(#{num})
        else
          return @#{var}_loop_line_no
        end
      END
    end

    def x_PRINT(c,num)
      # PRINT "Hello"
      statements = []
      while not c.empty?
        c,out = expression(c)
        statements << "print(#{out})"
        if c.empty?
          statements << "print \"\\n\""
        else
          delim = c.shift
          if delim == ","
            statements << "print \"\\t\""
          elsif delim == ";"
            break if c.empty?
          end
        end
      end
      statements << "return nextline(#{num})"
      statements
    end

    def x_GOTO(c,num)
      # GOTO 20
      number = c.shift
      ["return #{number}"]
    end

    def compile(c,number)
      command,*rest = c
      self.send("x_#{command}".to_sym,rest,number).join("\n")
    end
  end
end
