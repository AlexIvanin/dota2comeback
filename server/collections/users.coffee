@Referrals = new Meteor.Collection 'referrals'

Meteor.users.before.find excludeCounter
Referrals.before.find excludeCounter

Meteor.users.allow
	insert: (userId) -> Roles.userIsInRole userId, 'admin'
	update: (userId) -> Roles.userIsInRole userId, 'admin'
	remove: (userId) -> Roles.userIsInRole userId, 'admin'

Meteor.users.deny
	update: (userId, user, fields, modifier) ->
		return no if Roles.userIsInRole(userId, 'admin')
		return on if user._id isnt userId

		setData = modifier['$set']
		if setData and Object.keys(setData).length is 1
			if setData['profile.email']? or setData['profile.wm']? or setData['profile.qiwi']?
				return no
			else
				return on
		else
			return on

Meteor.methods
	addFriend: (friendId) ->
		@unblock()

		if @userId and friendId
			if (Meteor.users.findOne(@userId) and Meteor.users.findOne(friendId)) and (@userId isnt friendId)
				Meteor.users.update @userId, $addToSet: 'profile.friends': {_id: friendId, accepted: on}
				Meteor.users.update friendId, $addToSet: 'profile.friends': {_id: @userId, accepted: no}

	deleteFriend: (friendId) ->
		@unblock()

		if @userId and friendId
			if (Meteor.users.findOne(@userId) and Meteor.users.findOne(friendId)) and (@userId isnt friendId)
				Meteor.users.update @userId, $pull: 'profile.friends': _id: friendId
				Meteor.users.update friendId, $pull: 'profile.friends': _id: @userId

	acceptRequestFriend: (friendId) ->
		@unblock()

		if @userId and friendId
			if (Meteor.users.findOne(@userId) and Meteor.users.findOne(friendId)) and (@userId isnt friendId)
				Meteor.users.update {_id: @userId, 'profile.friends': {_id: friendId, accepted: no}}, $set: 'profile.friends.$.accepted': on

	declineRequestFriend: (friendId) ->
		@unblock()

		if @userId and friendId
			if (Meteor.users.findOne(@userId) and Meteor.users.findOne(friendId)) and (@userId isnt friendId)
				Meteor.users.update @userId, $pull: 'profile.friends': _id: friendId
				Meteor.users.update friendId, $pull: 'profile.friends': _id: @userId

	abortRequestFriend: (friendId) ->
		@unblock()

		if @userId and friendId
			if (Meteor.users.findOne(@userId) and Meteor.users.findOne(friendId)) and (@userId isnt friendId)
				Meteor.users.update @userId, $pull: 'profile.friends': _id: friendId
				Meteor.users.update friendId, $pull: 'profile.friends': _id: @userId

	setRef: (ref) ->
		@unblock()

		user = Meteor.users.findOne id: Number ref

		if user
			ips = @connection.httpHeaders['x-forwarded-for']
			match = ips.match /(.+), (.+)/
			ip = if match then match[1] else ips

			unless Referrals.findOne(ip)
				Referrals.insert
					_id: ip
					date: Date.now()
					refId: user._id

	setUserRole: (userId, role) ->
		@unblock()

		if @userId and Roles.userIsInRole(@userId, 'admin')
			if Meteor.users.findOne(userId)
				if role
					Roles.addUsersToRoles userId, role
				else
					Roles.setUserRoles userId, []

			else throw new Meteor.Error 'User not found'
		else throw new Meteor.Error 'Permission denied'

Meteor.publish null, ->
	@unblock()

	if @userId
		Meteor.users.find @userId, fields: 'services.resume': 0
	else
		@ready()

Meteor.publish null, ->
	@unblock()

	Meteor.users.find
		'status.online': on
	,
		sort:
			id: -1

Meteor.publish 'adminUsers', (limit) ->
	Meteor.users.find {},
		limit: limit or 50
		sort:
			createdAt: -1
		fields: 'services.resume': 0

Meteor.publish 'lastUser', ->
	@unblock()

	Meteor.users.find {},
		limit: 1
		sort:
			id: -1
		fields: 'services.resume': 0

Meteor.publish 'top', (limit) ->
	@unblock()

	Meteor.users.find
		'profile.rating.place':
			$exists: on
	,
		limit: limit or 100
		sort:
			'profile.rating.place': 1
		fields: 'services.resume': 0

Meteor.publish 'user', (id) ->
	@unblock()

	user = getUser id

	if user
		self = @
		cursors = []

		usersIds = [user._id]

		if user.invitedUser()
			usersIds.push user.invitedUser()._id

		cursors.push user.matches 20

		if Roles.userIsInRole(@userId, 'admin') or user._id is @userId
			cursors.push user.events()
			cursors.push user.tickets()
			cursors.push user.payOuts()
			user.referrals().forEach (referral) ->
				usersIds.push referral._id

		cursors.push Meteor.users.find
			_id: $in: usersIds
		,
			fields: 'services.resume': 0

		referralsHandle = user.referrals().observeChanges
			added: (id, fields) -> self.added 'users', id, fields
			removed: (id) -> self.removed 'users', id

		friendsHandle = user.friends().observeChanges 
			added: (id, fields) -> self.added 'users', id, fields
			changed: (id, fields) -> self.changed 'users', id, fields
			removed: (id) -> self.removed 'users', id

		@onStop ->
			referralsHandle.stop()
			friendsHandle.stop()

		return cursors
	else @ready()

Accounts.onCreateUser (options, user) ->
	if options.profile
		user.id = Number incrementCounter Meteor.users
		user.services.steam.steamID2 = new SteamID(user.services.steam.id).GetSteam2()
		user.services.steam.steamID3 = new SteamID(user.services.steam.id).GetSteam3()
		user.bans = []
		user.profile =
			name: options.profile.name
			money: 0
			friends: []
			heroes: []
			market:
				sellsMoney: 0
				sellsCount: 0
				buysMoney: 0
				buysCount: 0
			rating:
				one: score: 500
				five: score: 500
		user.createdAt = Date.now()

	user

Accounts.onLogin (params) ->
	Meteor.users.update params.user._id, $set: lastVisit: Date.now()

	if params.type is 'steam'
		agent = useragent.parse params.connection.httpHeaders['user-agent']
		agentObj =
			browser: agent.toAgent()
			os: agent.os.toString()
			device: agent.device.toString()

		ips = params.connection.httpHeaders['x-forwarded-for']
		match = ips.match /(.+), (.+)/
		ip = if match then match[1] else ips

		Events.insert
			isVisit: on
			userId: params.user._id,
			date: Date.now()
			ip: ip
			userAgent: agentObj

		unless params.user.profile.ref?
			referral = Referrals.findOne ip

			Meteor.users.update params.user._id, $set: 'profile.ref': if referral then referral.refId else 'none'

			if referral
				Referrals.remove ip