require 'fluent/plugin/filter_util'
require 'fluent/plugin/output'

module Fluent::Plugin
class FilterOutput < Output

  helpers :event_emitter

  include FilterUtil

  Fluent::Plugin.register_output('filter', self)

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

  # Define `router` method of v0.12 to support v0.10 or earlier
  unless method_defined?(:router)
    define_method("router") { Fluent::Engine }
  end

  def process(tag, es)
    if @add_prefix
      tag = @add_prefix + '.' + tag
    end
    es.each do |time, record|
      next unless passRules(record)
      router.emit(tag, time, record)
    end
  end
end

end
