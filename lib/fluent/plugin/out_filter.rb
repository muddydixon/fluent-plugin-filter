module Fluent
class FilterOutput < Output
  require 'fluent/plugin/filter_util'
  include FilterUtil

  Plugin.register_output('filter', self)

  config_param :all, :string, :default => 'allow'
  config_param :allow, :string, :default => ''
  config_param :deny, :string, :default => ''
  config_param :add_prefix, :string, :default => 'filtered'
  config_param :delim, :string, :default => ','

  attr_accessor :allows
  attr_accessor :denies

  def configure(conf)
    super
    @allows = toMap(@allow, @delim)
    @denies = toMap(@deny, @delim)
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
