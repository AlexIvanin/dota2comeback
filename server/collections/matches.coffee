@Matches = new Meteor.Collection 'matches'

Matches.before.find excludeCounter

Matches.allow
	insert: (userId) -> Roles.userIsInRole userId, 'admin'
	update: (userId) -> Roles.userIsInRole userId, 'admin'
	remove: (userId) -> Roles.userIsInRole userId, 'admin'

Meteor.setInterval ->
	Matches.find(status: 'inSearch', dateCreate: $lt: Date.now() - 3 * 60 * 60 * 1000).forEach (match) ->
		Matches.removeMatch match._id
, 60000

Meteor.publish 'matchesInSearchList', ->
	@unblock()
	self = @

	handle = Matches.find(
		status: 'inSearch'
	,
		sort: dateCreated: -1
		fields: password: 0
	).observeChanges
		added: (id, fields) ->
			self.added 'matches', id, fields

			user = Meteor.users.findOne fields.userId,
				fields: 'services.resume': 0

			if user
				self.added 'users', user._id, user

		changed: (id, fields) -> self.changed 'matches', id, fields
		removed: (id) -> self.removed 'matches', id

	@onStop -> handle.stop()
	@ready()

Meteor.publish 'matchesInGameList', ->
	@unblock()
	Matches.find
		status: 'inGame'
	,
		sort: dateCreated: -1
		fields: password: 0

Meteor.publish 'matchesFinishedList', (limit) ->
	Matches.find
		status: 'finished'
	,
		limit: limit or 25
		sort: dateFinished: -1
		fields: password: 0

Meteor.publish 'match', (id) ->
	@unblock()

	match = Matches.findOne(id)

	if match
		self = @

		handle = Matches.find({_id: id}, fields: password: 0).observeChanges
			added: (id, fields) ->
				self.added 'matches', id, fields

				fields.good.members.forEach (member) ->
					user = Meteor.users.findOne member._id,
						fields: 'services.resume': 0

					if user
						self.added 'users', user._id, user

				fields.bad.members.forEach (member) ->
					user = Meteor.users.findOne member._id,
						fields: 'services.resume': 0

					if user
						self.added 'users', user._id, user

			changed: (id, fields) ->
				self.changed 'matches', id, fields

				team = fields.bad or fields.good

				if team
					if team.members and team.members.length
						user = Meteor.users.findOne team.members[0]._id,
							fields: 'services.resume': 0

						self.added 'users', user._id, user

			removed: (id) -> self.removed 'matches', id

		@onStop -> handle.stop()
		@ready()
	else
		@ready()


@timeoutHandles = {}
@setTimeoutWithID = (id, time, callback) ->
	if id in timeoutHandles
		Meteor.clearTimeout timeoutHandles[id]

	timeoutHandles[id] = Meteor.setTimeout callback, time

@removeTimeoutWithID = (id) ->
	Meteor.clearTimeout timeoutHandles[id]
	delete timeoutHandles[id]

Matches.removeMatch = (matchID) ->
	match = Matches.findOne matchID

	match.good.members.forEach (member) ->
		Meteor.users.update member._id,
			$inc: 'profile.money': match.money

	match.bad.members.forEach (member) ->
		Meteor.users.update member._id,
			$inc: 'profile.money': match.money

	Matches.remove match._id

Meteor.methods
	removeMatch: (matchID) ->
		@unblock()

		if @userId and Roles.userIsInRole @userId, 'admin'
			Matches.removeMatch matchID

	createMatch: (params) ->
		@unblock()
		self = @

		throw new Meteor.Error 'Войдите в систему' unless @userId

		check params, Object
		check params.type, Number
		check params.mode, Number
		check params.money, Number
		check params.team, String
		check params.tv_enable, Boolean

		unless params.team is 'good' or params.team is 'bad'
			throw new Meteor.Error 'Неправильное название команды'
		throw new Meteor.Error 'Не правильное количество игроков' if params.type < 1 or params.type > 5

		if params.password?
			check params.password, String

		if params.type isnt 5
			check params.towers, Number
			check params.kills, Number

			throw new Meteor.Error 'Не правильное количество вышек' if params.towers < 0 or params.towers > 2
			throw new Meteor.Error 'Не правильное количество убийств' if params.kills < 0 or params.kills > 5

			if params.type > 1
				unless params.mode is 1 or params.mode is 2 or params.mode is 4 or params.mode is 5 or params.mode is 11
					throw new Meteor.Error 'Не правильный мод'

				check params.creeps, Object

				hasLanes = no
				for lane of params.creeps
					if params.creeps[lane]
						hasLanes = on
						break
				throw new Meteor.Error 'Не выбраны крипы на карте' unless hasLanes

			else
				unless params.mode is 4 or params.mode is 5 or params.mode is 11
					throw new Meteor.Error 'Не правильный мод'

			if params.type is 1
				if params.mode is 11
					check params.heroID, String
					unless params.heroID is '0'
						hero = Heroes.findOne params.heroID
						throw new Meteor.Error 'Данного героя не существует' unless hero

		else
			unless params.mode is 1 or params.mode is 2 or params.mode is 4 or params.mode is 5
				throw new Meteor.Error 'Не правильный мод'

		user = Meteor.users.findOne @userId

		throw new Meteor.Error 'Вы уже в другом матче' if user.currentMatch()
		throw new Meteor.Error 'Не достаточно средств' if user.profile.money < params.money
		throw new Meteor.Error 'Неправильная ставка' if params.money < Config.get('minMoney')

		match =
			_id: String incrementCounter Matches
			aborted: no
			dateCreate: Date.now()
			userId: @userId
			status: 'inSearch'
			gamestatus: 'startingServer'
			preparation: no
			money: params.money
			mode: params.mode
			type: "#{params.type}x#{params.type}"
			maxMembersCount: params.type * 2
			good:
				members: []
			bad:
				members: []
			tv_enable: params.tv_enable

		if params.password?
			match.password = params.password
			match.hasPassword = on

		if params.type isnt 5
			match.towers = params.towers
			match.kills = params.kills
			match.withoutRunes = params.withoutRunes
			match.withoutNeutrals = params.withoutNeutrals

			if params.type is 1
				if params.mode is 11
					match.heroID = Number params.heroID
				match.creeps = top: no, mid: on, bot: no
			else
				match.creeps = params.creeps
		else
			match.creeps = top: on, mid: on, bot: on

		match[params.team].members.push
			_id: @userId
			connected: no
			ready: no

		Matches.insert match, ->
			Meteor.users.update self.userId, $inc: 'profile.money': -params.money

	matchTakeSlot: (matchId, team, password) ->
		@unblock()
		self = @

		if @userId
			check matchId, String
			check team, String

			unless team is 'good' or team is 'bad'
				throw new Meteor.Error 'Неправильное название команды'

			user = Meteor.users.findOne @userId
			match = Matches.findOne matchId

			if match.hasPassword
				check password, String
				throw new Meteor.Error 'Неверный пароль' if match.password isnt password

			throw new Meteor.Error 'Вы уже в другом матче' if user.currentMatch()
			throw new Meteor.Error 'Не достаточно средств' if user.profile.money < match.money
			throw new Meteor.Error 'Матча не существует' unless match

			preparation = match.realMembersCount() + 1 is match.maxMembersCount

			if team is 'good'
				unless match.teamGoodHasMoreSlots()
					throw new Meteor.Error '[TEAM GOOD] - Нет свободных слотов'
			else
				unless match.teamBadHasMoreSlots()
					throw new Meteor.Error '[TEAM BAD] - Нет свободных слотов'

			match[team].members.push
				_id: @userId
				connected: no
				ready: no

			Matches.update match._id, $set:
				good: match.good
				bad: match.bad
				preparation: preparation

			match = Matches.findOne match._id
			if match.preparation
				match.good.members.forEach (member) ->
					setTimeoutWithID member._id, 120000, ->
						match = Matches.findOne match._id

						if match and match.getMemberTeam(member._id)
							unless match.isMemberReady member._id
								Matches.update match._id,
									$pull: 'good.members': _id: member._id
									$set: preparation: no

								Meteor.users.update member._id, $inc: 'profile.money': match.money

								match = Matches.findOne match._id

								goodMembers = match.good.members.map (member) ->
									member.ready = no
									return member

								badMembers = match.bad.members.map (member) ->
									member.ready = no
									return member

								Matches.update match._id,
									$set:
										'good.members': goodMembers
										'bad.members': badMembers

				match.bad.members.forEach (member) ->
					setTimeoutWithID member._id, 120000, ->
						match = Matches.findOne match._id

						if match and match.getMemberTeam(member._id)
							unless match.isMemberReady member._id
								Matches.update match._id,
									$pull: 'bad.members': _id: member._id
									$set: preparation: no

								Meteor.users.update member._id, $inc: 'profile.money': match.money

								match = Matches.findOne match._id

								goodMembers = match.good.members.map (member) ->
									member.ready = no
									return member

								badMembers = match.bad.members.map (member) ->
									member.ready = no
									return member

								Matches.update match._id,
									$set:
										'good.members': goodMembers
										'bad.members': badMembers

			Meteor.users.update @userId, $inc: 'profile.money': -match.money

	matchLeaveSlot: ->
		@unblock()
		if @userId
			user = Meteor.users.findOne @userId
			match = user.currentMatch()

			throw new Meteor.Error 'Матча не существует' unless match
			throw new Meteor.Error 'Матч уже начался' unless match.status is 'inSearch'

			if match.realMembersCount() is 1
				Matches.remove match._id
			else
				match.good.members.forEach (member) -> removeTimeoutWithID member._id
				match.bad.members.forEach (member) -> removeTimeoutWithID member._id

				Matches.update match._id,
					$pull:
						'good.members': _id: @userId
						'bad.members': _id: @userId
					$set:
						preparation: no

				match = Matches.findOne match._id

				goodMembers = match.good.members.map (member) ->
					member.ready = no
					return member

				badMembers = match.bad.members.map (member) ->
					member.ready = no
					return member

				Matches.update match._id,
					$set:
						'good.members': goodMembers
						'bad.members': badMembers

			Meteor.users.update @userId, $inc: 'profile.money': match.money