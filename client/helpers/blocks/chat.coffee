init = no

Template.chat.helpers
	messages: -> Chat.find {}, sort: date: 1
	usersOnline: ->
		Meteor.users.find
			'status.online': on
		,
			sort: id: 1

Template.chat.rendered = ->
	element = $ '#chat'
	element.animate scrollTop: element.prop('scrollHeight'), 200
	init = on

Template.chat.destroyed = -> init = no

Template.chatMessage.rendered = ->
	if init
		element = $ '#chat'
		element.animate scrollTop: element.prop('scrollHeight'), 'slow'

Template.chat.events
	'click #chatMessageSendButton': -> sendChatMessage()
	'keypress #chatMessageTextInput': (e) -> sendChatMessage() if e.which is 13

sendChatMessage = ->
	Meteor.call 'chatSendMessage', $('#chatMessageTextInput').val()
	$('#chatMessageTextInput').val ''