# frozen_string_literal: true

module JSONPathPest
  # The standard `count` function.
  class CountFunctionExtension
    ARG_TYPES = [:nodes_expression].freeze
    RETURN_TYPE = :value_expression

    def call(node_list)
      node_list.length
    end
  end

  # The standard `length` function.
  class LengthFunctionExtension
    ARG_TYPES = [:value_expression].freeze
    RETURN_TYPE = :value_expression

    def call(obj)
      return :nothing unless obj.is_a?(Array) || obj.is_a?(Hash) || obj.is_a?(String)

      obj.length
    end
  end

  # The standard `match` function.
  class MatchFunctionExtension
    ARG_TYPES = %i[value_expression value_expression].freeze
    RETURN_TYPE = :logical_expression

    # @param cache_size [Integer] the maximum size of the regexp cache. Set it to
    #   zero or negative to disable the cache.
    # @param raise_errors [Boolean] if _false_ (the default), return _false_ when this
    #   function causes a RegexpError instead of raising the exception.
    def initialize(cache_size = 128, raise_errors: false)
      super()
      @cache_size = cache_size
      @raise_errors = raise_errors
      @cache = LRUCache.new(cache_size)
    end

    # @param value [String]
    # @param pattern [String]
    # @return Boolean
    def call(value, pattern)
      return false unless pattern.is_a?(String) && value.is_a?(String)

      if @cache_size.positive?
        re = @cache[pattern] || Regexp.new(full_match(pattern))
      else
        re = Regexp.new(full_match(pattern))
        @cache[pattern] = re
      end

      re.match?(value)
    rescue RegexpError
      raise if @raise_errors

      false
    end

    private

    def full_match(pattern)
      parts = [] # : Array[String]
      explicit_caret = pattern.start_with?("^")
      explicit_dollar = pattern.end_with?("$")

      # Replace '^' with '\A' and '$' with '\z'
      pattern = pattern.sub("^", "\\A") if explicit_caret
      pattern = "#{pattern[..-1]}\\z" if explicit_dollar

      # Wrap with '\A' and '\z' if they are not already part of the pattern.
      parts << "\\A(?:" if !explicit_caret && !explicit_dollar
      parts << JSONPathPest.map_iregexp(pattern)
      parts << ")\\z" if !explicit_caret && !explicit_dollar
      parts.join
    end
  end

  # The standard `search` function.
  class SearchFunctionExtension
    ARG_TYPES = %i[value_expression value_expression].freeze
    RETURN_TYPE = :logical_expression

    # @param cache_size [Integer] the maximum size of the regexp cache. Set it to
    #   zero or negative to disable the cache.
    # @param raise_errors [Boolean] if _false_ (the default), return _false_ when this
    #   function causes a RegexpError instead of raising the exception.
    def initialize(cache_size = 128, raise_errors: false)
      super()
      @cache_size = cache_size
      @raise_errors = raise_errors
      @cache = LRUCache.new(cache_size)
    end

    # @param value [String]
    # @param pattern [String]
    # @return Boolean
    def call(value, pattern)
      return false unless pattern.is_a?(String) && value.is_a?(String)

      if @cache_size.positive?
        re = @cache[pattern] || Regexp.new(JSONPathPest.map_iregexp(pattern))
      else
        re = Regexp.new(JSONPathPest.map_iregexp(pattern))
        @cache[pattern] = re
      end

      re.match?(value)
    rescue RegexpError
      raise if @raise_errors

      false
    end
  end

  # The standard `value` function.
  class ValueFunctionExtension
    ARG_TYPES = [:nodes_expression].freeze
    RETURN_TYPE = :value_expression

    def call(node_list)
      node_list.length == 1 ? node_list.first.value : :nothing
    end
  end

  # Map I-Regexp pattern to Ruby regex pattern.
  # @param pattern [String]
  # @return [String]
  def self.map_iregexp(pattern)
    escaped = false
    char_class = false
    mapped = String.new(encoding: "UTF-8")

    pattern.each_char do |c|
      if escaped
        mapped << c
        escaped = false
        next
      end

      case c
      when "."
        # mapped << (char_class ? c : "(?:(?![\\r\\n])\\P{Cs}|\\p{Cs}\\p{Cs})")
        mapped << (char_class ? c : "[^\\n\\r]")
      when "\\"
        escaped = true
        mapped << "\\"
      when "["
        char_class = true
        mapped << "["
      when "]"
        char_class = false
        mapped << "]"
      else
        mapped << c
      end
    end

    mapped
  end

  # A least recently used cache relying on Ruby hash insertion order.
  class LRUCache
    attr_reader :max_size

    def initialize(max_size = 128)
      @data = {}
      @max_size = max_size
    end

    # Return the cached value or nil if _key_ does not exist.
    def [](key)
      val = @data[key]
      return nil if val.nil?

      @data.delete(key)
      @data[key] = val
      val
    end

    def []=(key, value)
      if @data.key?(key)
        @data.delete(key)
      elsif @data.length >= @max_size
        @data.delete((@data.first || raise)[0])
      end
      @data[key] = value
    end

    def length
      @data.length
    end

    def keys
      @data.keys
    end
  end
end
