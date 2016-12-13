module Fluent
class FilterOutput < Output
  require 'fluent/plugin/filter_util'
  include FilterUtil

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

  # Define `router` method of v0.12 to support v0.10 or earlier
  unless method_defined?(:router)
    define_method("router") { Fluent::Engine }
  end

  def emit(tag, es, chain)
    if @add_prefix
      tag = @add_prefix + '.' + tag
    end
    es.each do |time, record|
      next unless passRules(record)
      router.emit(tag, time, record)
    end
    chain.next
  end
end

end
