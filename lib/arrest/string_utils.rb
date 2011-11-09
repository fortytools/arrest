class StringUtils
  class << self

    PLURALS = [['(quiz)$', '\1zes'],['(ox)$', '\1en'],['([m|l])ouse$', '\1ice'],['(matr|vert|ind)ix|ex$', '\1ices'],
      ['(x|ch|ss|sh)$', '\1es'],['([^aeiouy]|qu)ies$', '\1y'],['([^aeiouy]|q)y$$', '\1ies'],['(hive)$', '\1s'],
      ['(?:[^f]fe|([lr])f)$', '\1\2ves'],['(sis)$', 'ses'],['([ti])um$', '\1a'],['(buffal|tomat)o$', '\1oes'],['(bu)s$', '\1es'],
      ['(alias|status)$', '\1es'],['(octop|vir)us$', '\1i'],['(ax|test)is$', '\1es'],['s$', 's'],['$', 's']]
    SINGULARS =[['(quiz)zes$', '\1'],['(matr)ices$', '\1ix'],['(vert|ind)ices$', '\1ex'],['^(ox)en$', '\1'],['(alias|status)es$', '\1'],
      ['(octop|vir)i$', '\1us'],['(cris|ax|test)es$', '\1is'],['(shoe)s$', '\1'],['[o]es$', '\1'],['[bus]es$', '\1'],['([m|l])ice$', '\1ouse'],
      ['(x|ch|ss|sh)es$', '\1'],['(m)ovies$', '\1ovie'],['[s]eries$', '\1eries'],['([^aeiouy]|qu)ies$', '\1y'],['[lr]ves$', '\1f'],
      ['(tive)s$', '\1'],['(hive)s$', '\1'],['([^f])ves$', '\1fe'],['(^analy)ses$', '\1sis'],
      ['([a]naly|[b]a|[d]iagno|[p]arenthe|[p]rogno|[s]ynop|[t]he)ses$', '\1\2sis'],['([ti])a$', '\1um'],['(news)$', '\1ews'], ['(.*)s$', '\1'], ['^(.*)$', '\1']]

    def singular(str)
      SINGULARS.each { |match_exp, replacement_exp| return str.gsub(Regexp.compile(match_exp), replacement_exp) unless str.match(Regexp.compile(match_exp)).nil?}
    end

    def plural(str)
      PLURALS.each   { |match_exp, replacement_exp| return str.gsub(Regexp.compile(match_exp), replacement_exp) unless str.match(Regexp.compile(match_exp)).nil? }
    end

    def plural?
      PLURALS.each {|match_exp, replacement_exp| return true if str.match(Regexp.compile(match_exp))}
      false
    end

    def blank? str
      str == nil || str == ""
    end

    def is_upper? str
      str == str.upcase
    end

    def underscore str
      word = str.to_s.dup
      word.gsub!(/::/, '/')
      word.gsub!(/([A-Z]+)([A-Z][a-z])/,'\1_\2')
      word.gsub!(/([a-z\d])([A-Z])/,'\1_\2')
      word.tr!("-", "_")
      word.downcase!
      word
    end

    def classify(str, upper_first = true)
      result = ""
      upperNext = false
      (singular str) .each_char do |c|
        if c == "_"
          upperNext = true
        else
          if upperNext || (result == "" && upper_first)
            result << c.upcase
          else
            result << c
          end
          upperNext = false
        end
      end
      result
    end
  end
end
