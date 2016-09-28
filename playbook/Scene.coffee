# credit to lmarkus/hubot-conversation for the original concept

Dialogue = require './Dialogue'
_ = require 'underscore'

defaultTimeout = process.env.DIALOGUE_TIMEOUT or 30000
defaultTimeoutLine = process.env.DIALOGUE_TIMEOUT_LINE or 'Timed out! Please start again.'

# handles array of participants engaged in dialogue
# while engaged the robot will only follow the given dialogue choices
# entering a user scene will engage the user
# entering a user scene will engage the whole room
# entering a userRoom scene will engage the user in that room only
# @param robot, a hubot instance
# @param type (optional), the type of audience - room, user (default) or userRoom
class Scene
	constructor: (@robot, @type='user') ->
		@engaged = {} # dialogues of each engaged audience

		# add hubot middleware to re-route to internal matching while engaged
		@robot.receiveMiddleware (context, next, done) =>
			res = context.response
			audience = @whoSpeaks res.message
			@robot.logger.debug "Receiving from #{ audience }, checking dialogues..."
			if audience of @engaged
				@robot.logger.debug "#{ audience } engaged in dialogue, routing dialogue."
				res.finish() # don't process regular listeners
				@engaged[audience].receive res # let dialogue handle the response
				done() # don't process further middleware.
			else
				@robot.logger.debug "#{ audience } not engaged, continue as normal."
				next done

	# engage the audience in dialogue
	# @param res, the response object
	# @param {string} reply message text (optional)
	# @param {object} options key/vals for config, e.g overide timeout default
	enter: (res, args...) ->
		if typeof args[0] is 'string'
			reply = args[0]
			options = args[1]
		else
			options = args[0]

		# extend any missing options with defaults
		options ?= {}
		config = _.defaults options,
			timeout: defaultTimeout
			timeoutLine: defaultTimeoutLine
			reply: if @type is 'room' then false else true

		# setup dialogue to handle choices for response branching
		audience = @whoSpeaks res.message
		@robot.logger.debug "Engaging #{ @type } #{ audience } in dialogue"
		@engaged[audience] = new Dialogue @robot, res, config

		# send first line of dialogue if provided
		res.reply reply if reply?

		# remove audience from engaged participants on timeout or completion
		@engaged[audience].on 'timeout', () => @exit res, 'timed out'
		@engaged[audience].on 'complete', () => @exit res, 'completed'

		return @engaged[audience]

	# disengage an audience from dialogue (can help in case of error)
	exit: (res, reason) ->
		audience = @whoSpeaks res.message
		@robot.logger.debug "Disengaging #{ @type } #{ audience } from dialogue"
		@robot.logger.debug "Disengaged because dialogue #{ reason }" if reason?
		@engaged[audience]?.clearTimeout()
		delete @engaged[audience]

	# return the source of a message (ID of user or room)
	whoSpeaks: (msg) ->
		switch @type
			when 'user' then return msg.user.id
			when 'room' then return msg.room
			when 'userRoom' then return "#{ msg.user.id }:#{ msg.room }"

	# return the dialogue for an engaged audience
	dialogue: (audience) -> return @engaged[audience]

module.exports = Scene
