# -*- coding: utf-8 -*-

##
# @todo Allow the animation duration to be overridden
# @note The API here is alpha, I need to get a better feel for how it
#       should work.
#
# The idea here is to pull actions out from an object and put them
# in front of object to give AXElements more of a DSL feel to make
# communicating test steps more clear.
module Kernel

  ##
  # We assume that any method that has the first argument with a type
  # of AX::Element is intended to be an action and so #method_missing
  # will forward the message to the element.
  #
  # @param [String] name an action constant
  def method_missing method, *args
    arg = args.first
    super unless arg.kind_of?(AX::Element)
    arg.perform_action method
  end

  ##
  # Focus an element on the screen, if possible.
  def set_focus element
    set element, focused: true
  end

  ##
  # @note Technically, this method allows you to set multiple attributes
  #       on a single object with a single call; but this behaviour is
  #       likely to change in the future to only allow setting one attribute
  #       per call.
  # @todo In order to support the ideal syntax, I will have to alter
  #       Element#method_missing to return a triple (self, attr, value)
  #       in the case when an extra argument is passed.
  # @todo This needs to have a default key for setting, which is :value
  #       since you are usually setting the value
  # @todo We should check if the element can have focus set first, and if
  #       so then we should set focus first; unless we were setting focus
  #       in the first place
  #
  # The syntax kinda sucks, and you would think that the #set method should
  # belong to AX::Element, but I think taking it out of the class helps make
  # the abstraction more concrete.
  #
  # @example How to use it
  #   set scroll_bar, value: 10
  # @example How I would like it to work eventually
  #   set scroll_bar.value 10
  #
  # @param [AX::Element] element
  # @param [Hash] changes
  # @return [nil] do not rely on a return value
  def set element, changes
    changes.each_pair do |attr_symbol, value|
      element.set_attribute attr_symbol, value
    end
  end

  alias_method :ax_raise, :raise
  ##
  # Needed to override inherited {Kernel#raise} so that the raise action
  # works, but in such a way that the original {#raise} also works.
  def raise *args
    arg = args.first
    arg.kind_of?(AX::Element) ? arg.perform_action(:raise) : ax_raise(*args)
  end

  # @param [#to_s] string
  # @param [AX::Application] app
  def type string, app = AX::SYSTEM
    app.type_string string.to_s
  end

  ##
  # @todo Change this to register_for_notification:from: when the syntax
  #       is supported by YARD or someone complains, which ever comes
  #       first.
  #
  # @param [AX::Element] element
  # @param [String] notif
  def register_for_notification element, notif, &block
    # do the notif name translation here?
    element.on_notification notif, &block
  end

  # @param [Float] timeout number of seconds to wait for a notification
  def wait_for_notification timeout = 10.0
    AX.wait_for_notif timeout
  end

  ##
  # @overload move_mouse_to(element)
  #   Move the mouse to a UI element
  #   @param [AX::Element] arg
  #
  # @overload move_mouse_to(point)
  #   Move the mouse to an arbitrary point
  #   @param [CGPoint] arg
  #
  # @overload move_mouse_to([x,y])
  #   Move the mouse to an arbitrary point given as an two element array
  #   @param [Array(Float,Float)] arg
  def move_mouse_to arg
    if arg.kind_of?(AX::Element)
      arg = CGPoint.center(arg.position, arg.size)
    elsif arg.is_a?(Array)
      arg = CGPoint.new(*arg)
    end
    Mouse.move_to arg
  end

  ##
  # There are many reasons why you would want to cause a drag event
  # with the mouse. Perhaps you want to drag an object to another
  # place, or maybe you want to hightlight an area of the screen.
  #
  # In the most general of cases, you are alawys dragging to a point,
  # but having to specify the point yourself is not very helpful.
  #
  # We try to inspect the arguments of this method in order to better
  # determine what it is you want.
  #
  # If you want to
  def drag_mouse_to arg
    if arg.kind_of?(AX::Element)
      arg = CGPoint.center(arg.position, arg.size)
    elsif arg.is_a?(Array)
      arg = CGPoint.new(*arg)
    end
    Mouse.drag_to arg
  end

  ##
  # @todo You really want to be able to pass a scroll bar element
  #       and have the API move the mouse to the appropriate area
  #       and then run the scroll event(s).
  # @todo Need to expose the units option
  def scroll lines, element = nil
    move_mouse_to element if element
    Mouse.scroll lines
  end

  def click element = nil
    move_mouse_to element if element
    Mouse.click
  end

  def right_click element = nil
    move_mouse_to element if element
    Mouse.right_click
  end

  ##
  # @todo return the element for the window?
  #
  # A macro for showing the About window for an app.
  def show_about_window_for app
    set_focus app
    press app.menu_bar_item(title:(app.title))
    press app.menu_bar.menu_item(title: "About #{app.title}")
  end

  ##
  # @todo return the element for the window?
  # @todo handle cases where an app has no prefs?
  #
  # A macro for showing the About window for an app.
  def show_preferences_window_for app
    set_focus app
    press app.menu_bar_item(title:(app.title))
    press app.menu_bar.menu_item(title:'Preferences…')
  end

end