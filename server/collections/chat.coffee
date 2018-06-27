@Chat = new Meteor.Collection 'chat'
Chat.before.find excludeCounter

Chat.allow
	insert: (userId) -> Roles.userIsInRole userId, 'admin'
	update: (userId) -> Roles.userIsInRole userId, 'admin'
	remove: (userId) -> Roles.userIsInRole userId, 'admin'

Meteor.publish 'chat', ->
	self = @
	handles = {}

	publishUser = (userId) ->
		unless handles[userId]
			handles[userId] = Meteor.users.find(userId).observeChanges
				added: (id, fields) -> self.added 'users', id, fields
				changed: (id, fields) -> self.changed 'users', id, fields
				removed: (id) -> self.removed 'users', id

	chatHandle = Chat.find({}, sort: date: 1).observeChanges
		added: (id, fields) ->
			self.added 'chat', id, fields
			publishUser fields.userId

		changed: (id, fields) -> self.changed 'chat', id, fields
		removed: (id) -> self.removed 'chat', id

	@onStop ->
		chatHandle.stop()

		Object.keys(handles).forEach (id) ->
			handles[id].stop()

	@ready()

init = no

Chat.find({}, sort: date: 1).observeChanges
	added: (id, fields) ->
		if init and Chat.find().count() > 50
			Chat.remove Chat.findOne({}, sort: date: 1)._id

init = on