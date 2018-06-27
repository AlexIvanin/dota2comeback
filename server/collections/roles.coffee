Meteor.publish null, ->
	@unblock()

	Meteor.roles.find {}, sort: name: 1

Roles.createRole 'admin' unless Meteor.roles.findOne name: 'admin'

Meteor.roles.allow
	insert: (userId) -> Roles.userIsInRole userId, 'admin'
	update: (userId) -> Roles.userIsInRole userId, 'admin'
	remove: (userId) -> Roles.userIsInRole userId, 'admin'