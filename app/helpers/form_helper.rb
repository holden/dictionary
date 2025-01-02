module FormHelper
  def catalyst_form_with(**options, &block)
    options[:builder] = CatalystFormBuilder
    form_with(**options, &block)
  end
end

class CatalystFormBuilder < ActionView::Helpers::FormBuilder
  def text_field(method, options = {})
    options[:class] = "form-input #{options[:class]}"
    super
  end

  def submit(value = nil, options = {})
    options[:class] = "btn-primary #{options[:class]}"
    super
  end
end 