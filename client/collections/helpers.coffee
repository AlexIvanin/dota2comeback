Matches.helpers
	isMyMatch: -> !!Matches.findOne _id: @_id, $or: [{'good.members._id': Meteor.userId()}, {'bad.members._id': Meteor.userId()}]
	currentUserHasMoney: -> Meteor.user().profile.money >= @money
	currentUserMoneyLeft: -> @money - Meteor.user().profile.money
	currentUserIsReady: ->
		goodMembers = _.where(@good.members, _id: Meteor.userId(), ready: on)
		badMembers = _.where(@bad.members, _id: Meteor.userId(), ready: on)
		!!(goodMembers.length or badMembers.length)

UI.registerHelper 'getHero', (heroID) -> Heroes.findOne heroID

News.helpers
	denyComment: -> @oneComment and newsComments.findOne(noveltyId: @_id, userId: Meteor.userId())