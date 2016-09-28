Scene = require '../playbook/Scene'
_ = require 'underscore'

module.exports = (robot) ->

	soloScene = new Scene robot, 'user'
	groupScene = new Scene robot, 'room'
	locationScene = new Scene robot, 'userRoom'

	robot.hear /play/, (res) ->
		dialogue = groupScene.enter res, "OK, I'm it! MARCO!"
		marcoPolo = (res) ->
			if Math.floor(Math.random() * 6) + 1 < 6
				dialogue.choice /polo/i, "MARCO!", (res) -> marcoPolo res
			else
				res.reply "I got you!"
		marcoPolo res

	robot.respond /clean the house/, (res) ->
		dialogue = soloScene.enter res, 'Sure, where should I start? [Kitchen] or [Bathroom]'
		dialogue.choice /kitchen/i, 'On it boss!'
		dialogue.choice /bathroom/i, 'Do I really have to?', () ->
			dialogue.choice /yes/, 'Ugh, fine!'

	robot.hear /jump/, (res) ->
		dialogue = locationScene.enter res, 'Sure, How many times?'
		dialogue.choice /([0-9]+)/i, (res) ->
			times = parseInt res.match[1], 10
			res.emote 'Jumps' for [0...times]

	robot.respond /.*the mission/, (res) ->
		res.reply 'Your have 5 seconds to accept your mission, or this message will self-destruct'
		dialogue = soloScene.enter res,
			timeout: 5000 # 5 second timeout
		# overrride timeout method
		dialogue.onTimeout = (res) ->
			res.emote ":bomb: Boom!"
		dialogue.choice /yes/i, 'Great! Here are the details...'

	robot.respond /whos talking/i, (res) ->
		soloParticipants = _.keys soloScene.engaged
		groupParticipants = _.keys groupScene.engaged
		locationParticipants = _.keys locationScene.engaged
		IDs = _.union soloParticipants, groupParticipants, locationParticipants
		if IDs.length
			res.reply "im in dialogue with these IDs: #{ IDs.join ', ' }"
		else
			res.reply "nobody right now"
