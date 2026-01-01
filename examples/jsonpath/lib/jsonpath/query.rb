# frozen_string_literal: true

module JSONPathPest
  Query = Data.define(:segments) do
    def to_s = "$#{segments.map(&:to_s).join}"

    def find(root)
      nodes = [Node.new(root, [], root)]
      segments.each { |segment| nodes = segment.resolve(nodes) }
      NodeList.new(nodes)
    end

    def singular?
      segments.each do |segment|
        return false if segment.instance_of?(DescendantSegment)
        return false unless segment.selectors.length == 1 &&
                            (segment.selectors[0].is_a?(NameSelector) ||
                              segment.selectors[0].is_a?(IndexSelector))
      end
      true
    end

    def empty? = segments.empty?
  end
end
