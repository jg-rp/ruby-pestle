# frozen_string_literal: true

module JSONPathPest
  Node = Data.define(:value, :location, :root) do
    def to_s = "Node({#{path.inspect}})"

    def path
      norm = location.map do |p|
        p.is_a?(String) ? "[#{JSONPathPest.canonical_string(p)}]" : "[#{p}]"
      end
      "$#{norm.join}"
    end

    def new_child(value, key)
      Node.new(value, location + [key], root)
    end
  end

  class NodeList < Array; end
end
