@configCollection = new Meteor.Collection 'config'

@Config =
	set: (key, value, isPublic) ->
		if Meteor.isServer
			configCollection.upsert key: key,
				$set:
					value: value
					isPublic: isPublic
		else Meteor.call 'Config.set', key, value, isPublic
	get: (key) ->
		result = configCollection.findOne key: key
		result.value if result

if Meteor.isServer
	configCollection.allow
		insert: (userId) -> Roles.userIsInRole userId, 'admin'
		update: (userId) -> Roles.userIsInRole userId, 'admin'
		remove: (userId) -> Roles.userIsInRole userId, 'admin'

	Meteor.methods
		'Config.set': (key, value, isPublic) -> Config.set key, value, isPublic if Roles.userIsInRole(@userId, 'admin') or !Meteor.users.findOne()

	Meteor.publish null, ->
		if Roles.userIsInRole @userId, 'admin' or !Meteor.users.findOne() then configCollection.find()
		else configCollection.find isPublic: true