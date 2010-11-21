module Basic
  module BasicLib
    def rnd(num)
      rand*num.to_f
    end

    def chr_string(int)
      int.chr
    end

    def int(num)
      num.to_i
    end
  end
end
