@mathWinMoney = (money) ->
	money = Number money
	percent = Number Config.get if money < 25 then 'percent10r' else if money < 100 then 'percent25r' else if money < 300 then 'percent100r' else if money >= 300 then 'percent300r'

	winMoney = money - money * percent * 0.01
	return Number winMoney.toFixed 2

Matches.helpers
	winMoney: -> mathWinMoney @money

	getTextGameStatus: ->
		switch @gamestatus
			when 'startingServer'	then 'Запуск сервера'
			when 'started'			then 'Сервер запущен'
			when 'playersLoad'		then 'Ожидание игроков'
			when 'heroSelection'	then 'Выбор героев'
			when 'strategyTime'		then 'Выбор героев'
			when 'preGame'			then 'Подготовка'
			when 'gameInProgress'	then 'Идет игра'
			when 'postGame'			then 'Закончен'

	getTextMode: ->
		switch @mode
			when 1 then 'All Pick'
			when 5 then 'All Random'
			when 2 then 'Captains Mode'
			when 4 then 'Single Draft'
			when 11 then 'Mid Only'

	hasParams: -> on if @heroID or @towers or @kills or @withoutRunes or @withoutNeutrals or @hasPassword or @tv_enable
	hero: -> Heroes.findOne String @heroID
	realMembersCount: -> @good.members.length + @bad.members.length
	teamGoodHasMoreSlots: -> @good.members.length < Number @type[0]
	teamBadHasMoreSlots: -> @bad.members.length < Number @type[2]
	teamGoodLeftSlots: -> Number(@type[0]) - @good.members.length
	teamBadLeftSlots: -> Number(@type[2]) - @bad.members.length

	membersReady: ->
		goodMembers = _.filter(@good.members, (member) -> member.ready).length
		badMembers = _.filter(@bad.members, (member) -> member.ready).length
		return goodMembers + badMembers

	isMemberReady: (userId) ->
		memberGoodReady = _.where @good.members, _id: userId, ready: on
		memberBadReady = _.where @bad.members, _id: userId, ready: on

		!!(memberGoodReady.length or memberBadReady.length)

	isMemberWinner: (userId) ->
		Matches.findOne
			_id: @_id,
			$or: [
				{$and: [
					{'good.members._id': userId}
					{'good.winner': on}
				]}
				{$and: [
					{'bad.members._id': userId}
					{'bad.winner': on}
				]}
			]

	getMemberTeam: (userId) ->
		memberGoodReady = _.where @good.members, _id: userId
		memberBadReady = _.where @bad.members, _id: userId

		if memberGoodReady.length then 'good'
		else if memberBadReady.length then 'bad'

	getMember: (userId) -> _.find @[@getMemberTeam userId].members, (member) -> member._id is userId

	droplet: -> Droplets.findOne matchID: @_id

Meteor.methods
	matchReady: ->
		if @userId
			user = Meteor.users.findOne @userId
			match = user.currentMatch()

			if match and match.status is 'inSearch'
				unless @isSimulation
					removeTimeoutWithID @userId

				Matches.update {_id: match._id, 'good.members._id': @userId}, $set: 'good.members.$.ready': on
				Matches.update {_id: match._id, 'bad.members._id': @userId}, $set: 'bad.members.$.ready': on

				match = Matches.findOne match._id

				if match.membersReady() is match.realMembersCount()
					Matches.update match._id,
						$set:
							status: 'inGame'
							preparation: no
							dateStarted: Date.now()
					, ->
						if Meteor.isServer
							Servers.start match