module Triage
  def Object.attr_bool_reader(sym)
    module_eval "def #{sym}?; @#{sym}; end"
  end
end
