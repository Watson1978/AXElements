require 'accessibility/graph'

module Accessibility::Debug

  ##
  # Get a list of elements, starting with an element you give, and riding
  # the hierarchy up to the top level object (i.e. the {AX::Application}).
  #
  # @example
  #
  #   element = AX::DOCK.list.application_dock_item
  #   path_for element # => [AX::ApplicationDockItem, AX::List, AX::Application]
  #
  # @param [AX::Element]
  # @return [Array<AX::Element>] the path in ascending order
  def path_for *elements
    element = elements.last
    return path(elements << element.parent) if element.respond_to? :parent
    return elements
  end

  ##
  # @note This is an unfinished feature
  #
  # Make a `dot` format graph of the tree, meant for graphing with
  # GraphViz.
  #
  # @return [String]
  def graph_for root
    dot = Accessibility::Graph.new(root)
    dot.build!
    dot.to_s
  end

  ##
  # Dump a tree to the console, indenting for each level down the
  # tree that we go, and inspecting each element.
  #
  # @example
  #
  #   puts dump_for app
  #
  # @return [String]
  def dump_for element
    output = element.inspect + "\n"
    element.each_child_with_level do |element, depth|
      output << "\t"*depth + element.inspect + "\n"
    end
    output
  end

end
