
_ = require 'underscore'

# convert sets of semantic key/vale conditions to regex capture groups
# also accepts straight regex or strings to convert to regex
# if an array is given, multiple conditions can be combined
# config determines flags and pre-filtering input
class Conditioner
	constructor: (condition, options={}) ->

		# merge defaults and options to get config
		@config = _.defaults options,
			matchWords: true
			ignoreCase: true
			ignorePunctuation: true
		@b = if @config.matchWords then '\\b' else '' # word boundary capture toggle
		@i = if @config.ignoreCase then 'i' else '' # ignore case flag toggle

		# generate expressions from given conditions
		@expressions = []
		@expression condition if condition?

	# convert range of condition formats to regular expression group
	expression: (condition, options={}) ->
		return @expressions.push condition if _.isRegExp.condition
		return @expressions.push toRegExp condition if typeof condition is 'string'
		if typeof condition is 'object'
			for type, value of condition
				@expressions.push @create type, value

	# convert strings to regular expressions
	toRegExp: (str) ->
		match = str.match new RegExp '^/(.+)/(.*)$'
		new RegExp match[1], match[2] if match

	# create regex for a value from various condition types
	create: (type, value) ->
		switch type
			# match the whole thing
			when 'is' then new RegExp "^(#{value})$", @i
			# match the beginning / first word (if matchWords)
			when 'starts' then new RegExp "^(#{value})#{@b}", @i
			# match the end / last word (if matchWords)
			when 'ends' then new RegExp "#{@b}(#{value})$", @i
			# match a part / word (if matchWords)
			when 'contains' then new RegExp "#{@b}(#{value})#{@b}", @i
			# exclude a part / word (if matchWords)
			when 'excludes' then new RegExp "^((?!#{@b}#{value}#{@b}).)*$", @i
			# match anything after value / next word (if matchWords)
			when 'after' then new RegExp "(?:#{value}\\s)([\\w\\-]+)", @i
			# match anything before value / prev word (if matchWords)
			when 'before' then new RegExp "#{@b}([\\w\\-]+)(?:\\s#{value})", @i
			# match a given range
			when 'range' then new RegExp "#{@b}([#{value}])#{@b}", @i

	# test a string against stored conditions and config
	# returns successful if all conditions meet
	# full match properties can be accessed from this.matches
	compare: (str) ->
		str = str.replace /[^\w\s]/g, '' if @config.ignorePunctuation
		@matches = _.map @expressions, (re) -> str.match re
		return _.every @matches # true if all trythy

	# extract parts of a string matching conditions
	# returns array of captured parts
	# full match properties can be accessed from this.matches
	capture: (str) ->
		str = str.replace /[^\w\s]/g, '' if @config.ignorePunctuation
		@matches = _.map @expressions, (re) -> str.match re
		return _.pluck @matches, 1

	# verbose outputs for a range of tests against current conditions
	degug: (tests) ->
		#TODO

coffeeTest = new Conditioner
	starts: 'order|get'
	contains: 'coffee(s)?'
	range: '1-6'
	after: 'for'
	ends: 'please'
	excludes: 'not'

# console.log coffeeTest.expressions
console.log coffeeTest.capture 'Order 5 coffees for me please'
console.log coffeeTest.capture 'Get 2 coffees for Tim please'
console.log coffeeTest.capture 'Order 1 coffee please'
# console.log coffeeTest.matches
