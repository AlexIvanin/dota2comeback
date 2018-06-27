@getUser = (id) -> Meteor.users.findOne $or: [{_id: id}, {id: Number id}, {'services.steam.steamID2': id}, {'services.steam.steamID3': id}]

Meteor.users.helpers
	steamID: -> @services.steam.steamID2
	avgRating: -> (@profile.rating.one.score + @profile.rating.five.score) / 2

	friends: ->
		if @profile.friends?
			Meteor.users.find
				_id:
					$in: @profile.friends.map (friend) -> friend._id if friend.accepted
				,
					fields:
						'id': 1
						'profile.name': 1
						'services.steam.avatar': 1

	matches: (type, limit) ->
		if typeof(type) is 'number'
			limit = type
			type = null

		request = 
			$and: [
				$or: [
					{'good.members._id': @_id}
					{'bad.members._id': @_id}
				]
				, status: 'finished'
				, aborted: no
			]

		request.type = type if type

		Matches.find request, limit: limit or 0, sort: dateFinished: -1

	currentMatch: -> Matches.findOne
		$and: [
			{
				$or: [
					{'good.members._id': @_id}
					{'bad.members._id': @_id}
				]
			}, {
				$or: [
					{status: 'inSearch'}
					{status: 'inGame'}
				]
			}
		]

	currentRole: -> @roles[0] if @roles
	events: -> Events.find {userId: @_id}, sort: date: -1
	visits: -> Events.find {userId: @_id, isVisit: on}, sort: date: -1
	payments: -> Events.find {userId: @_id, isPayment: on}, sort: date: -1
	payOuts: -> moneyRequests.find {userId: @_id}, sort: date: -1
	allowPayOut: ->
		lastPayOut = moneyRequests.findOne {userId: @_id}, sort: date: -1

		if lastPayOut
			return Date.now() - lastPayOut.date > 60 * 60 * 24 * 7 * 2 * 1000
		else
			return on

	payOutTimeLeft: ->
		lastPayOut = moneyRequests.findOne {userId: @_id}, sort: date: -1

		if lastPayOut
			return lastPayOut.date + 60 * 60 * 24 * 7 * 2 * 1000

	tickets: -> Tickets.find userId: @_id
	ticketMessages: -> ticketMessages.find userId: @_id
	invitedUser: -> Meteor.users.findOne @profile.ref
	referrals: (limit) -> Meteor.users.find {'profile.ref': @_id}, limit: limit, sort: createdAt: -1
	hasHero: (heroID) -> !!_.find @profile.heroes, (hero) -> hero._id is heroID
	items: -> Items.find userID: @_id, trade: $exists: no