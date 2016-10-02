
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
			escapeValues: false
		@b = if @config.matchWords then '\\b' else '' # word boundary capture toggle
		@i = if @config.ignoreCase then 'i' else '' # ignore case flag toggle

		# generate expressions from given conditions
		@expressions = []
		if typeof condition is 'array'
			@add c for c in condition
		else if condition?
			@add condition

	# add conditions to compare or capture with, converted if not already regex
	add: (condition, key) ->
		return @expressions.push condition if _.isRegExp.condition
		return @expressions.push toRegExp condition if typeof condition is 'string'
		if typeof condition is 'object'
			for type, value of condition
				re = @create type, value
				key ?= _.size @expressions # use int index if no named key
				@expressions[key] = re
		return @ # return self for chaining adds

	# convert strings to regular expressions
	toRegExp: (str) ->
		match = str.match new RegExp '^/(.+)/(.*)$'
		new RegExp match[1], match[2] if match

	# escape any special regex characters
	escapeRegExp: (str) ->
		str.replace /[\-\[\]\/\{\}\(\)\*\+\?\.\\\^\$\|]/g, "\\$&"

	# create regex for a value from various condition types
	create: (type, value) ->
		return false unless typeof value is 'string'
		value = @escapeRegExp value if @config.escapeValues
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
	# each conditions outcome saved to this.compared, for individual checks
	# full match properties can be accessed from this.matches
	compare: (str) ->
		str = str.replace /[^\w\s]/g, '' if @config.ignorePunctuation
		@matches = _.mapObject @expressions, (re) -> str.match re
		@compared = _.mapObject @matches, (match) -> match?
		return _.every @compared # true if all truthy

	# extract parts of a string matching conditions
	# returns array of captured parts (also available as this.captured)
	# full match properties can be accessed from this.matches
	capture: (str) ->
		str = str.replace /[^\w\s]/g, '' if @config.ignorePunctuation
		@matches = _.mapObject @expressions, (re) -> str.match re
		@captured = _.mapObject @matches, (match) -> match?[1]

# TESTING TODO: convert to unit tests

validOrder = new Conditioner()
	.add starts: 'order|get'
	.add contains: 'coffee(s)?'
	.add excludes: 'not'

orderDetails = new Conditioner()
	.add range: '1-3', 'qty'
	.add after: 'for', 'for'
	.add ends: 'please', 'polite'

questionFormat = new Conditioner ends: '?'
,
	matchWords: false
	escapeValues: true
	ignorePunctuation: false

testOrder = "Order 3 coffees for Tim please"
# console.log validOrder.compare testOrder
# console.log validOrder.expressions
# console.log validOrder.matches
# console.log validOrder.compared
console.log orderDetails.capture "Order 3 coffees for Tim"
console.log orderDetails.expressions
console.log orderDetails.matches
console.log orderDetails.captured

# console.log "Question (true):", questionFormat.compare "Is this a question?"
# console.log questionFormat.expressions
# console.log questionFormat.matches
# console.log "Question (false):", questionFormat.compare "This isn't a question."
# console.log questionFormat.expressions
# console.log questionFormat.matches
