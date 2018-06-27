Meteor.methods
	chatSendMessage: (message) ->
		@unblock()

		if @userId and message
			check message, String

			Chat.insert
				message: message
				userId: @userId
				date: Date.now()

Chat.helpers
	user: -> Meteor.users.findOne @userId