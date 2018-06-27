Template.newUser.helpers
	user: -> Meteor.users.findOne {}, sort: id: -1