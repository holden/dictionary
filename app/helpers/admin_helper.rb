module AdminHelper
  def current_controller?(controller_name)
    controller.controller_name == controller_name.to_s
  end
end 