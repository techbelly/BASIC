module Basic
  module Lexer
    
    def read(input,output=[],token='')
      if input.empty?
        output.push(token) unless token.empty?
        return output
      end

      first,rest = input[0..0],input[1..-1]

      if first == " "
        output.push(token) unless token.empty?
        read(rest, output)

      elsif first == "\""
        output.push(token) unless token.empty?
        read_string(rest, output)
      
      elsif "<".include?(first)
        output.push(token) unless token.empty?
        next_token = rest[0..0]
        case next_token
          when ">"
            read(rest[1..-1], output+["<>"],"")
          when "="
            read(rest[1..-1], output+["<="],"")
          else
            read(rest,output+["<"],"")
        end
      
      elsif ">".include?(first)
        output.push(token) unless token.empty?
        next_token = rest[0..0]
        case next_token
          when "="
            read(rest[1..-1], output+[">="],"")
          else
            read(rest,output+[">"],"")
        end
        
      elsif "-+*/=():;,".include?(first)
        output.push(token) unless token.empty?
        read(rest, output + [first], "")

      else
        read(rest,output,token+first)
      end

    end

    def read_string(input,output,string='')
      if input.empty?
        raise "Couldn't find end of string quote"
      end

      first,rest = input[0..0],input[1..-1]
      if first == "\""
        return read(rest,output+["\"#{string}\""],"")
      else
        return read_string(rest,output,string+first)
      end
    end
    
  end
end