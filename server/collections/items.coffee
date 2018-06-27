@Items = new Meteor.Collection 'items'
@Descriptions = new Meteor.Collection 'descriptions'

Items.before.find excludeCounter
Descriptions.before.find excludeCounter

Meteor.publish null, ->
	if @userId
		self = @
		user = Meteor.users.findOne @userId

		itemsCursor = user.items()
		descriptionsIDs = itemsCursor.map (item) -> item.descriptionID
		descriptionsCursor = Descriptions.find _id: $in: descriptionsIDs

		itemsCursor.observeChanges 
			added: (id, fields) ->
				description = Descriptions.findOne fields.descriptionID

				if description
					self.added 'descriptions', description._id, description 

		[itemsCursor, descriptionsCursor]

	else
		@ready()