# frozen_string_literal: true

# Just for fun, a bytecode compiler and stack-based virtual machine for
# compiling and running expressions parsed with our Pratt parser example.

require_relative "calculator_pratt"

# Calculator expression parser, interpreter, compiler and virtual machine.
module PrattExample
  Bytecode = Data.define(:instructions, :constants, :symbols)

  # Bytecode definition and helpers for encoding and decoding bytecode.
  module Code
    # 8-bit integer op codes
    OP_CONSTANT = 1
    OP_ADD = 2
    OP_SUB = 3
    OP_MUL = 4
    OP_DIV = 5
    OP_POW = 6
    OP_NEG = 7
    OP_FAC = 8
    OP_VAR = 9

    # @param name [String] Human readable name for the op code.
    # @param operand_widths [Array[Integer]] A byte count for each operand.
    OpDef = Data.define(:name, :operand_widths)

    # @type const DEFS: Hash[Integer, OpDef]
    DEFS = {
      OP_CONSTANT => OpDef.new("OpConstant", [2]),
      OP_VAR => OpDef.new("OpVar", [2]),
      OP_ADD => OpDef.new("OpAdd", []),
      OP_SUB => OpDef.new("OpSub", []),
      OP_MUL => OpDef.new("OpMul", []),
      OP_DIV => OpDef.new("OpDiv", []),
      OP_POW => OpDef.new("OpPow", []),
      OP_NEG => OpDef.new("OpNeg", []),
      OP_FAC => OpDef.new("OpFac", [])
    }.freeze

    # Make a bytecode instruction for operator `op` with operands from `operands`.
    # @param op [Integer] Op code.
    # @param operands [*Integer] Operands for `op`.
    # @return [Array[Integer]] Bytes for one instruction.
    def self.make(op, *operands)
      op_def = DEFS[op]
      raise "unknown op code #{op}" if op_def.nil?

      instruction = [op]

      # Encode operands with big-endian byte order.
      operands.zip(op_def.operand_widths) do |operand, byte_count|
        (byte_count - 1).downto(0) do |byte_index|
          instruction << ((operand >> (byte_index * 8)) & 0xFF)
        end
      end

      instruction
    end

    # Read operands for the operator defined by `op_def` from `instructions`
    # starting from `offset`.
    # @param op_def [OpDef]
    # @param instructions [Array[Integer]] Array of bytes.
    # @param offset [Integer] Index into `instructions`.
    # @return [[Array[Integer], Integer]] Operands read and new offset.
    def self.read(op_def, instructions, offset)
      operands = []

      op_def.operand_widths.each do |byte_count|
        value = 0
        (0...byte_count).each do |i|
          value = (value << 8) | instructions[offset + i]
        end
        operands << value
        offset += byte_count
      end

      [operands, offset]
    end

    # Read `n_bytes` bytes as a single operand from `instructions` starting at `offset`.
    def self.read_bytes(n_bytes, instructions, offset)
      value = 0
      (0...n_bytes).each { |i| value = (value << 8) | instructions[offset + i] }
      value
    end

    def self.to_s(instructions)
      buf = []
      i = 0

      while i < instructions.length
        op_def = DEFS[instructions[i]]
        raise "unknown op code #{instructions[i]}" if op_def.nil?

        operands, new_offset = read(op_def, instructions, i + 1)

        unless op_def.operand_widths.length == operands.length
          raise "expected #{op_def.operand_widths.length} operands, got #{operands.length}"
        end

        buf << format("%04d %s %s", i, op_def.name, operands.map(&:to_s).join(" "))
        i = new_offset
      end

      buf.join("\n")
    end
  end

  # A simple calculator compiler.
  class Compiler
    def initialize
      @instructions = []
      @constants = []
      @symbols = []
    end

    def compile(node)
      case node
      when IntExpr
        emit(Code::OP_CONSTANT, add_constant(node.value))
      when VarExpr
        emit(Code::OP_VAR, add_symbol(node.value))
      when InfixExpr
        compile(node.left)
        compile(node.right)
        case node.op
        when :+
          emit(Code::OP_ADD)
        when :-
          emit(Code::OP_SUB)
        when :*
          emit(Code::OP_MUL)
        when :/
          emit(Code::OP_DIV)
        when :**
          emit(Code::OP_POW)
        else
          raise "unknown infix operator #{node.op}"
        end
      when PrefixExpr
        compile(node.expr)
        case node.op
        when :-@
          emit(Code::OP_NEG)
        else
          raise "unknown prefix operator #{node.op}"
        end
      when PostfixExpr
        compile(node.expr)
        case node.op
        when :fact
          emit(Code::OP_FAC)
        else
          raise "unknown postfix operator #{node.op}"
        end
      else
        raise "unexpected expression #{node.class}"
      end
    end

    def bytecode
      Bytecode.new(@instructions, @constants, @symbols)
    end

    private

    def add_constant(const)
      @constants << const
      @constants.length - 1
    end

    def add_symbol(name)
      @symbols << name
      @symbols.length - 1
    end

    def emit(op, *operands)
      add_instruction(Code.make(op, *operands))
    end

    def add_instruction(instruction)
      @instructions.concat(instruction)
      @instructions.length - 1
    end
  end

  # A virtual machine running our simple calculator bytecode.
  class VM
    def initialize(bytecode, vars)
      @instructions = bytecode.instructions
      @constants = bytecode.constants
      @symbols = bytecode.symbols
      @stack = Array.new(2048)
      @sp = 0

      @vars = vars
    end

    def stack_top = @stack[@sp - 1]

    def run
      ip = 0
      loop do
        break if ip >= @instructions.length

        op = @instructions[ip]
        case op
        when Code::OP_CONSTANT
          const_index = Code.read_bytes(2, @instructions, ip + 1)
          ip += 3
          push(@constants[const_index])
        when Code::OP_VAR
          symbol_index = Code.read_bytes(2, @instructions, ip + 1)
          ip += 3

          name = @symbols[symbol_index]
          val = @vars[name]
          raise "undefined variable #{name}" if val.nil?

          push(val)
        when Code::OP_ADD
          right = pop
          left = pop

          push(left + right)
          ip += 1
        when Code::OP_SUB
          right = pop
          left = pop

          push(left - right)
          ip += 1
        when Code::OP_MUL
          right = pop
          left = pop

          push(left * right)
          ip += 1
        when Code::OP_DIV
          right = pop
          left = pop

          push(left / right)
          ip += 1
        when Code::OP_POW
          right = pop
          left = pop

          push(left**right)
          ip += 1
        when Code::OP_NEG
          push(-pop)
          ip += 1
        when Code::OP_FAC
          push(pop.fact)
          ip += 1
        end
      end
    end

    private

    def push(obj)
      @stack[@sp] = obj
      @sp += 1
      nil
    end

    def pop
      obj = @stack[@sp - 1]
      @sp -= 1
      obj
    end
  end

  def self.compile(prog)
    compiler = Compiler.new
    compiler.compile(prog)
    compiler.bytecode
  end

  def self.compile_and_run(prog, vars)
    bytecode = compile(prog)
    vm = VM.new(bytecode, vars)
    vm.run
    vm.stack_top
  end
end
