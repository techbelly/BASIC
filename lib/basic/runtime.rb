module Basic
  module Runtime
    def gosub(line_no)
      while line_no
        method_name = self.class.method_name(line_no)
        line_no = self.send(method_name)
      end
    end

    def readline(prompt)
      return Readline.readline(prompt)
    end

    def nextline(num)
      nextline = self.class.next(num)
    end
  end
end
