# AssertGenerator

This generates assert code from a result inside a unit or integration test.
This is useful if you have code that you've spiked or eyeballed as 'working' and you'd like to produce some assertions,
without editing the output of pretty-inspect manually or making it all up.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'assert_generator'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install assert_generator

## Usage

```
require 'assert_generator'

n = 2 + 3
res = {
    number: n,
    text: "(2 + 3) = #{n}"
}

AssertGenerator.generate_asserts(res, 'res')
```

Will output when run:

```
assert_equal 5, @res[:number]
assert_equal "(2 + 3) = 5", @res[:text]
```

which you can then paste into your code, and the asserts will pass.

### Supported source types

#### Scalars

`t = 2; AssertGenerator.generate_asserts(t, 't')` generates `assert_equal 2, t`

#### Arrays
`t = [1,2,3]; AssertGenerator.generate_asserts(t, 't')`

generates

```
assert_equal 3, t.count
assert_equal 1, t[0]
assert_equal 2, t[1]
assert_equal 3, t[2]
```

#### Ranges
`t = (4..7); AssertGenerator.generate_asserts { 't' }`

generates

```
assert_equal 4, t.first
assert_equal 7, t.last
```

#### Hashes

```
h = { a: 2 }
AssertGenerator.generate_asserts(h, 'h')
```

generates:

```
assert_equal 2, h[:a]
```

#### Dates

Generally
```
d = Date.new(2019,11,10)
AssertGenerator.generate_asserts(d, 'd')
```
generates:
```
assert_equal Date.new(2019, 11, 10), d
```

But with relative dates set (for when we have floating date fixtures):
```
d = Date.new(2019,11,10)
AssertGenerator.generate_asserts(relative_dates: 'Date.new(2019,11,1)') { 'd' }
```
generates:
```
assert_equal Date.new(2019,11,1) - 9.days, d
```
 
### Active Record

If you have an AR object `thing`, then `AssertGenerator.generate_asserts(thing, 'thing')`
will produce assertions for each attribute of the object.

Note that index values and similar may well be wrong, unless you are using fixtures with a specified id. 

Also, any class which quacks like AR by defining an `attributes` hash will be handled as for AR, allowing arbitrary classes to be tested.

## TODO

The attempt at reflecting values back is halfbaked, but a bit limited by the power of the ruby system to reflect.

## Development

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/sharesight/assert_generator.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
