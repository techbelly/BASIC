# frozen_string_literal: true
module Basic
  module ExpressionParser
    def pop_back_to_left_bracket(stack, output)
      until stack.empty?
        type, token = stack.pop
        break if type == :left_bracket
        raise SyntaxError 'Mismatched parentheses' if stack.empty?
        output << [type, token]
      end
    end

    def output_any_functions(stack, output)
      type, = stack[-1]
      output << stack.pop if type == :function || type == :array_ref
    end

    def expecting_unary?(tokens, i)
      return true if i == 0
      previous_token = tokens[i - 1]
      return true if BasicLib::OPERATORS.include?(previous_token)
      return true if '(,'.include?(previous_token)
      false
    end

    def output_higher_precedence_operators(stack, token, output)
      type, top = stack[-1]
      while type == :operator
        if BasicLib::PRECEDENCE[top] >= BasicLib::PRECEDENCE[token]
          output << stack.pop
          type, top = stack[-1]
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

      tokens.each_with_index do |token, i|
        if BasicLib::FUNCTIONS.include?(token)
          stack.push [:function, token]
        elsif token == '-' && expecting_unary?(tokens, i)
          stack.push [:operator, '-!-']
        elsif token == ','
          pop_back_to_left_bracket(stack, output)
          stack.push [:left_bracket, '(']
        elsif token == ')'
          pop_back_to_left_bracket(stack, output)
          output_any_functions(stack, output)
        elsif token == '('
          stack.push [:left_bracket, token]
        elsif BasicLib::OPERATORS.include?(token)
          output_higher_precedence_operators(stack, token, output)
          stack.push [:operator, token]
        elsif variable_name?(token) && tokens[i + 1] == '('
          stack.push [:array_ref, token]
        elsif variable_name?(token)
          output << [:variable, token]
        else
          token = '0' + token if token =~ /^\.\d+$/ # ruby 2.3 no longer allows .4 as float literal
          output << [:literal, eval(token)]
        end
      end

      output << stack.pop until stack.empty?

      output
    end
  end
end
