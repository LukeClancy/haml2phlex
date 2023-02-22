# Haml2phlex

A haml 2 phlex converter. haml and phlex are both used to render ruby views. See [phlex here](https://phlex.fun)

## Installation

Add this to your application's Gemfile:

```ruby
group :development do
    gem 'haml2phlex'
end
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install haml2phlex

## Usage

convert from HAML to Phlex.

this is an imperfect string-parsing-based converter from HAML to Phlex on a subset of HAML functionality
most commonly used.

this means results still need to be touched up before they are actually usable. However - this will get
rid of most the grunt work.

use as so in the rails console to output to the command line so you can copy paste:
```ruby
x = Haml2phlex::Haml2flex.new('user_customizes/_show.html.haml', spacer: "\t", base_root: "app/views/")
puts x.out
```

or to output to a corresponding file with class definitions etc. (in this case app/views/user_customizes/show.rb)
```ruby
x = Haml2phlex::Haml2flex.new('user_customizes/_show.html.haml', spacer: "\t", base_root: "app/views/")
puts x.to_file
```

## Example Input

```haml
 = form_for @user_customize do |f|
 	- if @user_customize.errors.any?
 		#error_explanation
 			%h2= "#{pluralize(@user_customize.errors.count, "error")} prohibited this user_customize from being saved:"
 			%ul
 				- @user_customize.errors.full_messages.each do |message|
 					%li= message

 	.actions
 		= f.submit 'Save'
```
## Example Output

```ruby
form_for @user_customize do |f|
    if @user_customize.errors.any?
    	div(:id=>"error_explanation") {
			h2() { "#{pluralize(@user_customize.errors.count, "error")} prohibited this user_customize from being saved:" } 
			ul() {
				@user_customize.errors.full_messages.each do |message|
					li() { message } 
				end
			}
		}
	end
	div(:class=>"actions") {
		f.submit 'Save'
	}
end
```

## Options

since 1.0.13 if you have a template method in your ApplicationView, the to_file function will acommidate that with a super do .... end.
This lets you do something like the below in your ApplicationView.

```ruby
def template(&)
	t = Time.now 
	yield
	Rails.logger.info "#{self.class.to_s} Phlex class took #{(Time.now - t) * 1000} ms"
end
```
Needless to say, this is nice for comparing timing with previous haml implementations

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/LukeClancy/haml2flex. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/LukeClancy/haml2flex/blob/master/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Haml2flex project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/LukeClancy/haml2flex/blob/master/CODE_OF_CONDUCT.md).
