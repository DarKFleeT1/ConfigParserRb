class ConfParser
  def initialize(path, overrides = [])
    load_config(path, overrides)
  end

  def to_obj(hash)
    hash.each do |k, v|
      if v.kind_of? Hash
        self.instance_variable_set("@#{k}", v)
        self.class.send(:define_method, k, proc{self.instance_variable_get("@#{k}")})
        self.class.send(:define_method, "#{k}=", proc{|v| self.instance_variable_set("@#{k}", v)})
        v.each do |k1, v1|
          self.instance_variable_get("@#{k}").instance_variable_set("@#{k1}", v1)
          self.instance_variable_get("@#{k}").class.send(:define_method, k1, proc{self.instance_variable_get("@#{k1}")})
          self.instance_variable_get("@#{k}").class.send(:define_method, "#{k1}=", proc{|v1| self.instance_variable_set("@#{k1}", v1)})
        end
      end
    end
  end

  def to_sym(hash)
   hash.inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo}
  end

  def load_config(file_path, overrides = [])
    string_overrides = []
    overrides.each do |o|
      string_overrides.push o.to_s
    end
    overrides = string_overrides

    file = File.new file_path, "r"
    config = {}
    group = ""
    attributes = {}

    while line = file.gets
      line.scan /^(\s*)\[(\w+)\](\s*)$/i do |s1, word, s2|
        if !attributes.empty?
          attributes = to_sym(attributes)
          config[group] = attributes
        end
        group = word
        attributes = {}
      end

      line.scan /^(\s*)(\w+)(\<(\w)+\>){0,1}(\s*)\=(\s*)(\"){0,1}([a-zA-Z0-9\/,\s]+)(\"){0,1}(\s*)((\;)(.*)){0,1}$/i do |s1, attribute, override, suffix, s2, s3, q1, value, q2, s4|

        quoted_value = "#{q1}#{value}#{q2}".strip
        if quoted_value =~ /^((\w+),)+(\w+)/i
          quoted_value = quoted_value.split ','
        end

        if !override.nil?
          override = override.gsub("<", "").gsub(">", "")
          if overrides.include? override
            attributes[attribute] = quoted_value
          end
        else
          attributes[attribute] = quoted_value
        end
      end
    end

    if !attributes.empty?
      attributes = to_sym attributes
      config[group] = attributes
    end

    to_obj(config)
  end
end


CONFIG = ConfParser.new("file.conf", ['ubuntu', :production])

puts CONFIG.common.paid_users_size_limit
puts CONFIG.ftp.name
puts CONFIG.ftp.path
puts CONFIG.http.params
puts defined? CONFIG.ftp.lastname
puts CONFIG.ftp.enabled
puts CONFIG.ftp[:path]
puts CONFIG.ftp

gets.chomp
