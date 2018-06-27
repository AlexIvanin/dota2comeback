Tickets.helpers
	author: -> Meteor.users.findOne @userId,
		fields:
			id: 1
			roles: 1
			'profile.name': 1
			'services.steam.avatar': 1

	messages: -> ticketMessages.find ticketId: @_id

ticketMessages.helpers
	author: ->
		Meteor.users.findOne @userId,
			fields:
				id: 1
				roles: 1
				'profile.name': 1
				'services.steam.avatar.full': 1