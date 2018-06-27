News.helpers
	comments: -> newsComments.find {noveltyId: @_id}, sort: date: 1

newsComments.helpers
	author: -> Meteor.users.findOne @userId