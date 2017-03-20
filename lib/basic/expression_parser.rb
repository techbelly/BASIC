module Basic
  module ExpressionParser

    def pop_back_to_left_bracket(stack,output)
      while !stack.empty?
        type,token = stack.pop
        if type == :left_bracket
          break
        elsif stack.empty?
          raise SyntaxError "Mismatched parentheses"
        else
          output << [type,token]
        end
      end
    end

    def output_any_functions(stack,output)
      type,top = stack[-1]
      if type == :function || type == :variable || type == :array_ref
        output << stack.pop
      end
    end

    def output_higher_precedence_operators(stack,token,output)
      type,top = stack[-1]
      while type == :operator
        if BasicLib::OPERATORS.index(top) > BasicLib::OPERATORS.index(token)
          output << stack.pop
          type,top = stack[-1]
        else
          break
        end
      end
    end

    def variable_name?(token)
      token =~ /^[A-Z][A-Z0-9]*\$?$/
    end

    def to_reverse_polish(tokens)
      output = []
      stack = []
      tokens.each_with_index do |token,i|
        case
          when token == ")"
            pop_back_to_left_bracket(stack,output)
            output_any_functions(stack,output)
          when token == ","
            pop_back_to_left_bracket(stack,output)
            stack.push [:left_bracket,"("]
          when token == "("
            stack.push [:left_bracket,token]
          when token == "-"
            if i == 0 || BasicLib::FUNCTIONS.include?(token[i-1])
              stack.push [:function,"NEG"]
            else
              output_higher_precedence_operators(stack,token,output)
              stack.push [:operator,token]
            end
          when BasicLib::FUNCTIONS.include?(token)
            stack.push [:function,token]
          when BasicLib::OPERATORS.include?(token)
             output_higher_precedence_operators(stack,token,output)
             stack.push [:operator,token]
          when variable_name?(token) && tokens[i+1] == "("
            stack.push [:array_ref,token]
          when variable_name?(token)
            output << [:variable,token]
          when token =~ /^\.\d+$/ # ruby 2.3 no longer allows .4 as float literal
            output << [:literal,eval("0"+token)]
          else
            output << [:literal,eval(token)]
        end
      end

      output << stack.pop while !stack.empty?

      output
    end
end
end
