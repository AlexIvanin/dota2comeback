@Events = new Meteor.Collection 'events'
Events.before.find excludeCounter

Events.allow
	insert: (userId) -> Roles.userIsInRole userId, 'admin'
	update: (userId) -> Roles.userIsInRole userId, 'admin'
	remove: (userId) -> Roles.userIsInRole userId, 'admin'

Meteor.publish 'payments', (limit) ->
	@unblock()

	if Roles.userIsInRole @userId, 'admin'
		self = @

		handle = Events.find(
			isPayment: on
		,
			sort: date: -1
			limit: limit or 25
		).observeChanges
			added: (id, fields) ->
				self.added 'events', id, fields

				user = Meteor.users.findOne fields.userId,
					fields: 'services.resume': 0

				if user
					self.added 'users', user._id, user

			changed: (id, fields) -> self.changed 'events', id, fields
			removed: (id) -> self.changed 'events', id

		@onStop -> handle.stop()
		@ready()
	else
		@ready()

Meteor.publish 'visits', (limit) ->
	@unblock()

	if Roles.userIsInRole @userId, 'admin'
		self = @

		handle = Events.find(
			isVisit: on
		,
			sort: date: -1
			limit: limit or 25
		).observeChanges
			added: (id, fields) ->
				self.added 'events', id, fields

				user = Meteor.users.findOne fields.userId,
					fields: 'services.resume': 0

				if user
					self.added 'users', user._id, user
			changed: (id, fields) -> self.changed 'events', id, fields
			removed: (id) -> self.changed 'events', id

		@onStop -> handle.stop()
		@ready()
	else
		@ready()