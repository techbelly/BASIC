module Basic
  module BasicLib
    FUNCTIONS = %w[ VAL RND INT CHR$ SIN GET GET$ INKEY INKEY$ ABS SQR ATN ]
    OPERATORS = %w[ + - * / = <> <= >= < > ( ) OR AND ]
    EXPRESSION_TERMINATORS = %w[ , : ; THEN TO ]

    def val(str)
      str.to_i
    end

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
    
    def sin(num)
      Math.sin(num)
    end
    
    def abs(num)
      num.abs
    end
    
    def inkey(wait_time)
      char = getbyte(wait_time=100)
      char ? char : -1
    end
    
    def inkey_string(wait_time)
      code = inkey(wait_time)
      code == -1 ? '' : code.chr
    end
    
    def get()
      getbyte
    end
    
    def get_string()
      get.chr
    end
    
  end
end
