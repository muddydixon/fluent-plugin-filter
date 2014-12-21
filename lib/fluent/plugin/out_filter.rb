module Fluent
class FilterOutput < Output
  Plugin.register_output('filter', self)

  config_param :all, :string, :default => 'allow'
  config_param :allow, :string, :default => ''
  config_param :deny, :string, :default => ''
  config_param :add_prefix, :string, :default => 'filtered'
  
  attr_accessor :allows
  attr_accessor :denies

  def configure(conf)
    super
    @allows = toMap(@allow)
    @denies = toMap(@deny)
  end

  def toMap (str)
    str.split(/\s*,\s*/).map do|pair|
      k, v = pair.split(/\s*:\s*/, 2)
      if v =~ /^\d+$/
        v = v.to_i
      elsif v =~ /^[\d\.]+(e\d+)?$/
        v = v.to_f
      elsif v =~ /^\/(\\\/|[^\/])+\/$/
        v = Regexp.new(v.gsub(/^\/|\/$/, ''))
      else
        v = v.gsub(/^[\"\']|[\"\']$/, '')
      end
      [k, v]
    end
  end

  def passRules (record)
    if @all == 'allow'
      @denies.each do |deny|
        if (deny[1].is_a? Regexp and record.has_key?(deny[0]) and record[deny[0]].match(deny[1])) or record[deny[0]] == deny[1]
          @allows.each do |allow|
            if (allow[1].is_a? Regexp and record.has_key?(allow[0]) and record[allow[0]].match(allow[1])) or record[allow[0]] == allow[1]
              return true
            end
          end
          return false
        end
      end
      return true
    else
      @allows.each do |allow|
        if (allow[1].is_a? Regexp and record.has_key?(allow[0]) and record[allow[0]].match(allow[1])) or record[allow[0]] == allow[1]
          @denies.each do |deny|
            if (deny[1].is_a? Regexp and record.has_key?(deny[0]) and record[deny[0]].match(deny[1])) or record[deny[0]] == deny[1]
              return false
            end
          end
          return true
        end
      end
      return false
    end
  end

  def emit(tag, es, chain)
    if @add_prefix
      tag = @add_prefix + '.' + tag
    end
    es.each do |time, record|
      next unless passRules(record)
      Engine.emit(tag, time, record)
    end
    chain.next
  end
end

end
