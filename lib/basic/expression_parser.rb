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
      type, _ = stack[-1]
      if type == :function || type == :array_ref
        output << stack.pop
      end
    end

    def stack_top_operator?(stack)
      type, _ = stack[-1]
      [:function, :array_ref, :operator, :left_bracket].include? type
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
          when BasicLib::FUNCTIONS.include?(token)
            stack.push [:function,token]
          when token == "-" && (i == 0 || stack_top_operator?(stack))
            stack.push [:function,"NEG"]
          when token == ","
            pop_back_to_left_bracket(stack,output)
            stack.push [:left_bracket,"("]
          when token == ")"
            pop_back_to_left_bracket(stack,output)
            output_any_functions(stack,output)
          when token == "("
            stack.push [:left_bracket,token]
          when BasicLib::OPERATORS.include?(token)
             output_higher_precedence_operators(stack,token,output)
             stack.push [:operator,token]
          when variable_name?(token) && tokens[i+1] == "("
             stack.push [:array_ref,token]
          when variable_name?(token)
             output << [:variable,token]
          else
             token = "0" + token if token =~ /^\.\d+$/ # ruby 2.3 no longer allows .4 as float literal
             type, func = stack[-1]
             if type == :function && func == "NEG"
               stack.pop
               output << [:literal,eval("-"+token)]
             else
               output << [:literal,eval(token)]
             end
        end
      end

      output << stack.pop while !stack.empty?

      output
    end
end
end
