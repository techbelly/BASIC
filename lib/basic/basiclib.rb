module Basic
  module BasicLib
    FUNCTIONS = %w[ RND INT CHR$ INKEY$ ABS VAL ASC SGN SQR SIN ATN ]
    OPERATORS = %w[ + - * / = <> <= >= < > ( ) OR AND ]
    EXPRESSION_TERMINATORS = %w[ , : ; THEN TO ]

    def rnd(num)
      rand*num.to_f
    end

    def chr_string(int)
      int.chr
    end

    def int(num)
      num.to_i
    end
    
    def sqr(num)
      Math.sqrt(num)
    end
    
    def atn(num)
      Math.atan(num)
    end
    
    def abs(num)
      num.abs
    end
    
  end
end
