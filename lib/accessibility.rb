require 'mouse'
require 'ax/element'
require 'ax/application'
require 'ax/systemwide'
require 'accessibility/debug'

##
# The main AXElements namespace.
module Accessibility
  extend Accessibility::Debug

  class << self


    # @group Finding an object at a point

    ##
    # Get the current mouse position and return the top most element at
    # that point.
    #
    # @return [AX::Element]
    def element_under_mouse
      element_at_point Mouse.current_position, for: AX::SystemWide.new
    end

    ##
    # Get the top most object at an arbitrary point on the screen.
    #
    # @overload element_at_point([x, y], from: app)
    #   @param [Array(Float,Float)] point
    #
    # @overload element_at_point(CGPoint.new(x,y), from: app)
    #   @param [CGPoint] point
    #
    # @return [AX::Element]
    def element_at_point point, for: app
      x, y = *point.to_a
      app.element_at_point x, y
    end


    # @group Finding an application object

    ##
    # @todo Find a way for this method to work without sleeping;
    #       consider looping begin/rescue/end until AX starts up
    # @todo This needs to handle bad bundle identifier's gracefully
    #
    # This is the standard way of creating an application object. It will
    # launch the app if it is not already running and then create the
    # accessibility object.
    #
    # However, this method is a _HUGE_ hack in cases where the app is not
    # already running; I've tried to register for notifications, launch
    # synchronously, etc., but there is always a problem with accessibility
    # not being ready.
    #
    # If this method fails to find an app with the appropriate bundle
    # identifier then it will return nil, eventually.
    #
    # @example
    #
    #   application_with_bundle_identifier 'com.apple.mail' # wait a few seconds
    #
    # @param [String] bundle a bundle identifier
    # @param [Float] sleep_time how long to wait between polling
    # @return [AX::Application,nil]
    def application_with_bundle_identifier bundle, sleep_time = 2
      10.times do |count|
        apps = NSRunningApplication.runningApplicationsWithBundleIdentifier bundle
        if apps.empty?
          launch_application bundle
          sleep sleep_time
        else
          return application_with_pid apps.first.processIdentifier
        end
      end
    end

    ##
    # Get the accessibility object for an application given its localized
    # name. This will only work if the application is already running.
    #
    # @example
    #
    #   application_with_name 'Mail'
    #
    # @param [String] name name of the application to launch
    # @return [AX::Application,nil]
    def application_with_name name
      # @todo We don't launch apps if they are not running, but we could if
      #       we used `NSWorkspace#launchApplication`, but it will be a headache
      NSRunLoop.currentRunLoop.runUntilDate Time.now
      workspace = NSWorkspace.sharedWorkspace
      app = workspace.runningApplications.find { |app| app.localizedName == name }
      application_with_pid(app.processIdentifier) if app
    end

    include Accessibility::Core
    include Accessibility::Factory

    ##
    # Get the accessibility object for an application given its PID.
    #
    # @example
    #
    #   application_with_pid 54687
    #
    # @return [AX::Application]
    def application_with_pid pid
      process_element application_for pid
    end

    # @endgroup


    private

    ##
    # Asynchronously launch an application given the bundle identifier.
    #
    # @param [String] bundle the bundle identifier for the app
    # @return [Boolean]
    def launch_application bundle
      NSWorkspace.sharedWorkspace.launchAppWithBundleIdentifier bundle,
                                                       options: NSWorkspaceLaunchAsync,
                                additionalEventParamDescriptor: nil,
                                              launchIdentifier: nil
    end

  end
end
