@Tickets = new Meteor.Collection 'tickets'
@ticketMessages = new Meteor.Collection 'ticketMessages'

Tickets.before.find excludeCounter
ticketMessages.before.find excludeCounter

Meteor.publish 'adminTicketsOpen', (limit) ->
	@unblock()

	if Roles.userIsInRole @userId, 'admin'
		self = @

		handle = Tickets.find(
			closed: no
		,
			limit: limit or 50
			sort: date: -1
			fields:
				description: 0
		).observeChanges 
			added: (id, fields) ->
				self.added 'tickets', id, fields

				user = Meteor.users.findOne fields.userId,
					fields: 'services.resume': 0

				if user
					self.added 'users', user._id, user

			changed: (id, fields) -> self.changed id, fields
			removed: (id) -> self.removed 'tickets', id

		@onStop -> handle.stop()
		@ready()
	else
		@ready()

Meteor.publish 'adminTicketsClosed', (limit) ->
	@unblock()

	if Roles.userIsInRole @userId, 'admin'
		self = @

		handle = Tickets.find(
			closed: on
		,
			limit: limit or 50
			sort: date: -1
			fields:
				description: 0
		).observeChanges 
			added: (id, fields) ->
				self.added 'tickets', id, fields

				user = Meteor.users.findOne fields.userId,
					fields: 'services.resume': 0

				if user
					self.added 'users', user._id, user

			changed: (id, fields) -> self.changed id, fields
			removed: (id) -> self.removed 'tickets', id

		@onStop -> handle.stop()
		@ready()
	else
		@ready()

Meteor.publish 'adminTicket', (id) ->
	@unblock()

	if Roles.userIsInRole @userId, 'admin'
		ticket = Tickets.findOne id

		if ticket
			self = @

			ticketHandle = Tickets.find(id).observeChanges
				changed: (id, fields) -> self.changed 'tickets', id, fields

			ticketMessagesHandle = ticketMessages.find(ticketId: id).observeChanges
				added: (id, fields) ->
					self.added 'ticketMessages', id, fields

					user = Meteor.users.findOne fields.userId,
						fields: 'services.resume': 0

					if user
						self.added 'users', user._id, user

			@onStop ->
				ticketHandle.stop()
				ticketMessagesHandle.stop()

			@added 'tickets', id, ticket
			@added 'users', ticket.userId, ticket.author()
			@ready()
		else
			@ready()
	else
		@ready()

Meteor.publish 'ticket', (id) ->
	@unblock()

	ticket = Tickets.findOne id
	if ticket
		if ticket.userId is @userId
			self = @

			ticketHandle = Tickets.find(id).observeChanges
				changed: (id, fields) -> self.changed 'tickets', id, fields

			ticketMessagesHandle = ticketMessages.find(ticketId: id).observeChanges
				added: (id, fields) ->
					user = Meteor.users.findOne fields.userId, fields: 'services.resume': 0

					self.added 'ticketMessages', id, fields
					if user
						self.added 'users', user._id, user

			@onStop ->
				ticketHandle.stop()
				ticketMessagesHandle.stop()

			@added 'tickets', id, ticket
			@ready()
		else
			@ready()
	else
		@ready()

Meteor.methods
	ticketAdd: (urgency, title, description) ->
		@unblock()

		if @userId
			check urgency, String
			check title, String
			check description, String

			if title.length > 50
				throw new Meteor.Error('Длина короткого описания должна быть не больше 50 символов')

			Tickets.insert
				_id: String incrementCounter Tickets
				date: Date.now()
				urgency: urgency
				title: title
				description: description
				userId: @userId
				closed: no

	ticketsAddAdminReply: (ticketId, message, closeTicket) ->
		@unblock()

		if @userId and Roles.userIsInRole @userId, 'admin'
			if message and closeTicket?
				ticket = Tickets.findOne ticketId

				throw new Meteor.Error('Такого тикета не существует') unless ticket
				throw new Meteor.Error('Данный тикет закрыт') if ticket.closed

				ticketMessages.insert
					_id: String incrementCounter ticketMessages
					date: Date.now()
					ticketId: ticketId
					message: message
					userId: @userId
					isAdmin: on

				if closeTicket
					Tickets.update ticketId, $set: closed: on

	ticketsAddReply: (ticketId, message) ->
		@unblock()

		if @userId
			if message
				ticket = Tickets.findOne ticketId

				throw new Meteor.Error('Такого тикета не существует') unless ticket
				throw new Meteor.Error('Данный тикет закрыт') if ticket.closed

				ticketMessages.insert
					_id: String incrementCounter ticketMessages
					date: Date.now()
					ticketId: ticketId
					message: message
					userId: @userId