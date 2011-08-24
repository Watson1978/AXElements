##
# [Reference](http://developer.apple.com/library/mac/#documentation/Carbon/Reference/QuartzEventServicesRef/Reference/reference.html).
#
# @todo Inertial scrolling
# @todo Bezier paths
# @todo More intelligent default duration
# @todo Point arguments should accept a pair tuple
module Mouse; end

class << Mouse

  ##
  # Number of animation steps per second
  #
  # @return [Number]
  FPS     = 120

  ##
  # @note We keep the number as a rational to try and avoid rounding
  #       error introduced by the way MacRuby deals with floats.
  #
  # Smallest unit of time allowed for an animation step
  #
  # @return [Number]
  QUANTUM = Rational(1, FPS)

  ##
  # Available unit constants when scrolling
  #
  # @return [Hash{Symbol=>Fixnum}]
  UNIT = {
    line:  KCGScrollEventUnitLine,
    pixel: KCGScrollEventUnitPixel
  }

  ##
  # Return the coordinates of the mouse using the flipped coordinate
  # system.
  #
  # @return [CGPoint]
  def current_position
    CGEventGetLocation(CGEventCreate(nil))
  end

  ##
  # Move the mouse from the current position to the given point.
  #
  # @param [CGPoint] point
  # @param [Float] duration animation duration, in seconds
  def move_to point, duration = 0.2
    animate KCGEventMouseMoved, KCGMouseButtonLeft, current_position, point, duration
  end

  ##
  # Click and drag from the current mouse position to the given point.
  #
  # @param [CGPoint] point
  # @param [Float] duration animation duration, in seconds
  def drag_to point, duration = 0.2
    click point do |_|
      animate KCGEventLeftMouseDragged, KCGMouseButtonLeft, current_position, point, duration
    end
  end

  ##
  # @todo Need to double check to see if I introduce any inaccuracies.
  #
  # Scrolling too much or too little in a period of time will cause the
  # animation to look weird, possibly causing the app to mess things up.
  #
  # @param [Fixnum] amount number of pixels/lines to scroll; positive
  #   to scroll up or negative to scroll down
  # @param [Float] duration animation duration, in seconds
  # @param [Fixnum] units :line scrolls by line, :pixel scrolls by pixel
  def scroll amount, duration = 0.2, units = :line
    units   = UNIT[units] || raise(ArgumentError, "#{units} is not a valid unit")
    steps   = (FPS * duration).floor
    current = 0.0
    steps.times do |step|
      done     = (step+1).to_f / steps
      scroll   = ((done - current)*amount).floor
      # the fixnum arg represents the number of scroll wheels
      # on the mouse we are simulating (up to 3)
      event = CGEventCreateScrollWheelEvent(nil, units, 1, scroll)
      CGEventPost(CGHIDEventTap, event)
      sleep QUANTUM
      current += scroll.to_f / amount
    end
  end

  ##
  # A standard click. Default position is the current position.
  #
  # @yield You can pass a block that will be executed after clicking down
  #        but before clicking up
  # @param [CGPoint] point
  def click point = current_position
    event = CGEventCreateMouseEvent(nil, KCGEventLeftMouseDown, point, KCGMouseButtonLeft)
    CGEventPost(KCGHIDEvent, event)

    yield event if block_given?

    CGEventSetType(event, KCGEventLeftMouseUp)
    CGEventPost(KCGHIDEventTap, event)
  end

  ##
  # Standard secondary click. Default position is the current position.
  #
  # @yield You can pass a block that will be executed after clicking down
  #        but before clicking up
  # @param [CGPoint] point
  def right_click point = current_position
    event = CGEventCreateMouseEvent(nil, KCGEventRightMouseDown, point, KCGMouseButtonRight)
    CGEventPost(KCGHIDEvent, event)

    yield event if block_given?

    CGEventSetType(event, KCGEventRightMouseUp)
    CGEventPost(KCGHIDEventTap, event)
  end
  alias_method :secondary_click, :right_click

  ##
  # Perform a double left click at an arbitrary point. Defaults to clicking
  # at the current position.
  #
  # @param [CGPoint] point
  def double_click point = current_position
    event = CGEventCreateMouseEvent(nil, KCGEventLeftMouseDown, point, KCGMouseButtonLeft)
    CGEventPost(KCGHIDEventTap, event)
    CGEventSetType(event,       KCGEventLeftMouseUp)
    CGEventPost(KCGHIDEventTap, event)

    CGEventSetIntegerValueField(event, KCGMouseEventClickState, 2)
    CGEventSetType(event,       KCGEventLeftMouseDown)
    CGEventPost(KCGHIDEventTap, event)
    CGEventSetType(event,       KCGEventLeftMouseUp)
    CGEventPost(KCGHIDEventTap, event)
  end

  ##
  # Click with an arbitrary mouse button, using numbers to represent
  # the mouse button. The left button is 0, right button is 1, middle
  # button is 2, and the rest are not documented!
  #
  # @yield You can pass a block that will be executed after clicking down
  #        but before clicking up
  # @param [CGPoint]
  # @param [Number]
  def arbitrary_click point = current_position, button = KCGMouseButtonCenter
    event = CGEventCreateMouseEvent(nil, KCGEventOtherMouseDown, point, button)
    CGEventPost(KCGHIDEvent, event)

    yield event if block_given?

    CGEventSetType(event, KCGEventOtherMouseUp)
    CGEventPost(KCGHIDEventTap, event)
  end


  private

  ##
  # @todo Refactor this method, it is a bit ugly...
  #
  # Executes a mouse movement animation. It can be a simple cursor
  # move or a drag depending on what is passed to `type`.
  def animate type, button, from, to, duration
    steps = (FPS * duration).floor
    xstep = (to.x - from.x) / steps
    ystep = (to.y - from.y) / steps
    steps.times do
      from.x += xstep
      from.y += ystep
      event = CGEventCreateMouseEvent(nil, type, from, button)
      CGEventPost(KCGHIDEventTap, event)
      sleep QUANTUM
    end
    $stderr.puts 'Not moving anywhere' if from == to
    event = CGEventCreateMouseEvent(nil, type, to, button)
    CGEventPost(KCGHIDEventTap, event)
    sleep QUANTUM
  end

end
