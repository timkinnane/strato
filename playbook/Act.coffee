Scene = require './Scene'
Conditioner = require 'conditioner-regex'
_ = require 'underscore'

# An Act executes a dynamic model of branching dialogue
# A results object is produced with the dialogue outcomes
# @param robot, a hubot instance
# @param {object} outline - model of behaviour and dialogue choices
# e.g.
#
class Act
	constructor: (@robot, @outline) ->
