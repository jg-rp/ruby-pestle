# Ruby Pestle

Pestle is a Ruby port of the [Rust pest](https://pest.rs/) parsing library - a PEG (Parsing Expression Grammar) parser generator.

We use the same grammar syntax as Pest v2. See the [Pest Book](https://pest.rs/book/).

Language grammars are parsed to an internal representation from which input text can be parsed into token pairs. Currently there is no code gen phase.

As of version 0.1.0, grammar optimization is unimplemented. Even with some optimization passes, Pest implemented in pure Ruby is never going to be as fast as a hand-crafted parser. It might still be useful for prototyping and/or testing during language design.

## Links

- Change log: https://github.com/jg-rp/ruby-pestle/blob/main/CHANGELOG.md
- RubyGems: https://rubygems.org/gems/pestle
- Source code: https://github.com/jg-rp/ruby-pestle
- Issue tracker: https://github.com/jg-rp/ruby-pestle/issues

## Usage

Please see [examples](https://github.com/jg-rp/ruby-pestle/tree/main/examples) and refer to [pair.rb](https://github.com/jg-rp/ruby-pestle/blob/main/lib/pestle/pair.rb) for the token API.

### Debugging

Given this example grammar for a calculator with grammar-encoded operator precedence.

```ruby
GRAMMAR = <<~GRAMMAR
  program     =  { SOI ~ expr ~ EOI }
  expr        =  { add_sub }   // top-level expression

  add_sub     =  { mul_div ~ (add_op ~ mul_div)* }
  add_op      = _{ add | sub }
    add       =  { "+" }
    sub       =  { "-" }

  mul_div     =  { pow_expr ~ (mul_op ~ pow_expr)* }
  mul_op      = _{ mul | div }
    mul       =  { "*" }
    div       =  { "/" }

  pow_expr    =  { prefix ~ (pow_op ~ pow_expr)? } // right-associative
  pow_op      = _{ pow }
    pow       =  { "^" }

  prefix      =  { (neg)* ~ postfix }
    neg       =  { "-" }

  postfix     =  { primary ~ (fac)* }
    fac       =  { "!" }

  primary     = { int | ident | "(" ~ expr ~ ")" }
    int       = @{ (ASCII_NONZERO_DIGIT ~ ASCII_DIGIT* | "0") }
    ident     = @{ ASCII_ALPHA+ }

  WHITESPACE  = _{ " " | "\t" | NEWLINE }
GRAMMAR

START_RULE = :program

parser = Pestle::Parser.from_grammar(GRAMMAR)
```

We can dump a tree view of the grammar.

```ruby
puts parser.tree_view
```

**Output** (we're just showing the first three rules here)

```
Pestle::Grammar::Rule                      program = { SOI ~ expr ~ EOI }
    └── Pestle::Grammar::Sequence          SOI ~ expr ~ EOI
        ├── Pestle::Grammar::Identifier    SOI
        ├── Pestle::Grammar::Identifier    expr
        └── Pestle::Grammar::Identifier    EOI

Pestle::Grammar::Rule                  expr = { add_sub }
    └── Pestle::Grammar::Identifier    add_sub

Pestle::Grammar::Rule                                  add_sub = { mul_div ~ (add_op ~ mul_div)* }
    └── Pestle::Grammar::Sequence                      mul_div ~ (add_op ~ mul_div)*
        ├── Pestle::Grammar::Identifier                mul_div
        └── Pestle::Grammar::Repeat                    (add_op ~ mul_div)*
            └── Pestle::Grammar::Group                 (add_op ~ mul_div)
                └── Pestle::Grammar::Sequence          add_op ~ mul_div
                    ├── Pestle::Grammar::Identifier    add_op
                    └── Pestle::Grammar::Identifier    mul_div
```

We can also dump arbitrary token pairs for inspections.

```ruby
pairs = parser.parse(START_RULE, "1 + 2 * 3!")
puts pairs.dumps
```

**Output**

```
- program
  - expr > add_sub
    - mul_div > pow_expr > prefix > postfix > primary > int: "1"
    - add: "+"
    - mul_div
      - pow_expr > prefix > postfix > primary > int: "2"
      - mul: "*"
      - pow_expr > prefix > postfix
        - primary > int: "3"
        - fac: "!"
  - EOI: ""
```

There's also `Pair#dump` and `Pairs#dump`, which return a more verbose, JSON-like representation of the generated token pairs.

```
puts JSON.pretty_generate(pairs.dump)
```

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

Ruby Pestle is a port of [Rust pest](https://pest.rs/). See `LICENSE_PEST.txt`.
