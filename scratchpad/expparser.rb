OPERATORS = %w[+ *]

FUNCTION_ARITY = {
  "INT" => 1,
  "CHR" => 2,
  "RIGHT" => 2,
  "LEFT" => 2
}

FUNCTIONS = FUNCTION_ARITY.keys

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
    if OPERATORS.index(top) > OPERATORS.index(token)
      output << stack.pop
      type,top = stack[-1]
    else
      break
    end
  end
end

def variable_name?(token)
  token =~ /^[A-Z]+$/
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
      when FUNCTIONS.include?(token)
        stack.push [:function,token]
      when variable_name?(token) && tokens[i+1] == "("
        stack.push [:array_ref,token]
      when variable_name?(token) 
        stack.push [:variable,token]
      when OPERATORS.include?(token)
        output_higher_precedence_operators(stack,token,output)
        stack.push [:operator,token]
      else
        output << [:literal,token]
    end
  end
  
  output << stack.pop while !stack.empty?
  
  output
end

def evaluate(tokens)
  stack = []
  tokens.each do |type,token|
    case type
      when :operator
        augend, addend = stack.pop, stack.pop
        stack.push augend.send(token.to_sym,addend)
      when :function
        
      when :array_ref
        
      when :variable
        
      else
        stack.push token
    end
  end
  stack.pop
end

puts to_reverse_polish(%w[A ( 3 , 2 ) + INT ( 2 ) * B + LEFT ( RIGHT ( 2 , 3 ) , 1 ) ]).inspect
puts to_reverse_polish(%w[ ( 3 + 2 ) * 2]).inspect
puts evaluate [[:literal, 3], [:literal, 2], [:operator, "+"], [:literal, 2], [:operator, "*"]]
