if Meteor.isServer
	Matches.handleRequest = (request, server) ->
		console.log request
		console.log server

		if server.address is Config.get 'serverIP'
			Matches.update server.id, $set: 'server.logSocketPort': server.port

			match = Matches.findOne
				status: 'inGame'
				$or: [
					_id: server.id
				,
					'server.logSocketPort': server.port
				]

			if request.player
				user = Meteor.users.findOne 'services.steam.id': new SteamID(request.player.steamid).GetCommunityID()

				return unless user

				switch request.type
					when 'entered the game' then Meteor.users.update user._id, $set: onServer: on
					when 'disconnected' then Meteor.users.update user._id, $set: onServer: no

			if match
				switch request.type
					when 'disconnected'
						Matches.update {_id: match._id, 'good.members._id': user._id}, $set: 'good.members.$.connected': no
						Matches.update {_id: match._id, 'bad.members._id': user._id}, $set: 'bad.members.$.connected': no

					when 'connected'
						Matches.update {_id: match._id, 'good.members._id': user._id}, $set: 'good.members.$.connected': on
						Matches.update {_id: match._id, 'bad.members._id': user._id}, $set: 'bad.members.$.connected': on

					when 'server_message'
						switch request.message
							when 'quit'
								if match.status isnt 'finished'
									match.good.members.forEach (member) ->
										Meteor.users.update member._id,
											$inc: 'profile.money': match.money
											$set: onServer: no

									match.bad.members.forEach (member) ->
										Meteor.users.update member._id,
											$inc: 'profile.money': match.money
											$set: onServer: no

									Matches.remove match._id

					when 'MATCH_END'
						systemMoney = Config.get('money') or 0

						goodMembersRatings = match.good.members.map (member) ->
							if match.type is '1x1'
								Meteor.users.findOne(member._id).profile.rating.one.score or 500
							else if match.type is '5x5'
								Meteor.users.findOne(member._id).profile.rating.five.score or 500

						avgRatingGood = averageOfArray goodMembersRatings

						badMembersRatings = match.bad.members.map (member) ->
							if match.type is '1x1'
								Meteor.users.findOne(member._id).profile.rating.one.score or 500
							else if match.type is '5x5'
								Meteor.users.findOne(member._id).profile.rating.five.score or 500

						avgRatingBad = averageOfArray badMembersRatings

						if request.winTeam is 'good'
							Matches.update match._id,
								$set:
									status: 'finished'
									dateFinished: Date.now()
									'good.winner': on
									'good.avgRating': avgRatingGood
									'bad.looser': on
									'bad.avgRating': avgRatingBad

							match.good.members.forEach (member) ->
								user = Meteor.users.findOne member._id

								request =
									$inc:
										'profile.money': match.money + match.winMoney()
										'profile.stats.matches.count': 1
										'profile.stats.matches.wins': 1
									$set: onServer: no

								if match.type is '1x1'
									difRating = (avgRatingBad - user.profile.rating.one.score) / 100
									request.$inc['profile.rating.one.score'] = 25 + (Math.abs 2 * difRating)

								else if match.type is '5x5'
									difRating = (avgRatingBad - user.profile.rating.five.score) / 100
									request.$inc['profile.rating.five.score'] = 25 + (Math.abs 2 * difRating)

								if user.profile.ref
									Meteor.users.update user.profile.ref,
										$inc:
											'profile.money': match.winMoney() * 0.01

								Meteor.users.update member._id, request

							match.bad.members.forEach (member) ->
								user = Meteor.users.findOne member._id

								request =
									$inc:
										'profile.stats.matches.count': 1
										'profile.stats.matches.loses': 1
									$set: onServer: no

								if match.type is '1x1'
									difRating = (avgRatingGood - user.profile.rating.one.score) / 100
									request.$inc['profile.rating.one.score'] = -(25 + (Math.abs 2 * difRating))

								else if match.type is '5x5'
									difRating = (avgRatingGood - user.profile.rating.five.score) / 100
									request.$inc['profile.rating.five.score'] = -(25 + (Math.abs 2 * difRating))

								Meteor.users.update member._id, request

							Config.set 'money', systemMoney + (match.money - match.winMoney()) * match.good.members.length, no

						else if request.winTeam is 'bad'
							Matches.update match._id,
								$set:
									status: 'finished'
									dateFinished: Date.now()
									'good.looser': on
									'good.avgRating': avgRatingGood
									'bad.winner': on
									'bad.avgRating': avgRatingBad

							match.bad.members.forEach (member) ->
								user = Meteor.users.findOne member._id

								request =
									$inc:
										'profile.money': match.money + match.winMoney()
										'profile.stats.matches.count': 1
										'profile.stats.matches.wins': 1
									$set: onServer: no

								if match.type is '1x1'
									difRating = (avgRatingGood - user.profile.rating.one.score) / 100
									request.$inc['profile.rating.one.score'] = 25 + (Math.abs 2 * difRating)
								else if match.type is '5x5'
									difRating = (avgRatingGood - user.profile.rating.five.score) / 100
									request.$inc['profile.rating.five.score'] = 25 + (Math.abs 2 * difRating)

								if user.profile.ref
									Meteor.users.update user.profile.ref,
										$inc:
											'profile.money': match.winMoney() * 0.01

								Meteor.users.update member._id, request

							match.good.members.forEach (member) ->
								user = Meteor.users.findOne member._id

								request =
									$inc:
										'profile.stats.matches.count': 1
										'profile.stats.matches.loses': 1
									$set: onServer: no

								if match.type is '1x1'
									difRating = (avgRatingBad - user.profile.rating.one.score) / 100
									request.$inc['profile.rating.one.score'] = -(25 + (Math.abs 2 * difRating))
								else if match.type is '5x5'
									difRating = (avgRatingBad - user.profile.rating.five.score) / 100
									request.$inc['profile.rating.five.score'] = -(25 + (Math.abs 2 * difRating))

								Meteor.users.update member._id, request

							Config.set 'money', systemMoney + (match.money - match.winMoney()) * match.bad.members.length, no

						Servers.parseLogFile match, (stats) ->
							stats.forEach (stat) ->
								stat.deaths = 1 if stat.deaths is 0

								user = Meteor.users.findOne stat.userID

								if user.hasHero stat.heroID
									Meteor.users.update
										_id: stat.userID
										'profile.heroes._id': heroID
									,
										$inc:
											'profile.skill': ((stat.kills + stat.assists) / stat.deaths) * 10
											'profile.heroes.$.count': count: 1
								else
									Meteor.users.update stat.userID,
										$inc:
											'profile.skill': ((stat.kills + stat.assists) / stat.deaths) * 10
										$addToSet:
											'profile.heroes':
												_id: stat.userID
												count: 1

								Matches.update
									_id: match._id
									'good.members._id': stat.userID
								,
									$set:
										'good.members.$.heroID': stat.heroID
										'good.members.$.kills': stat.kills
										'good.members.$.deaths': stat.deaths
										'good.members.$.assists': stat.assists

								Matches.update
									_id: match._id
									'bad.members._id': stat.userID
								,
									$set:
										'bad.members.$.heroID': stat.heroID
										'bad.members.$.kills': stat.kills
										'bad.members.$.deaths': stat.deaths
										'bad.members.$.assists': stat.assists

							updateUsersTop()

					when 'MATCH_ABORT'
						match.good.members.forEach (member) ->
							Meteor.users.update member._id,
								$inc: 'profile.money': match.money
								$set: onServer: no

						match.bad.members.forEach (member) ->
							Meteor.users.update member._id,
								$inc: 'profile.money': match.money
								$set: onServer: no

						Matches.update match._id,
							$set:
								aborted: on
								status: 'finished'
								dateFinished: Date.now()

					when 'GAME_STATE'
						switch request.state
							when 0 then Matches.update match._id, $set: gamestatus: 'started'
							when 1 then Matches.update match._id, $set: gamestatus: 'playersLoad'
							when 2 then Matches.update match._id, $set: gamestatus: 'heroSelection'
							when 3 then Matches.update match._id, $set: gamestatus: 'strategyTime'
							when 4 then Matches.update match._id, $set: gamestatus: 'preGame'
							when 5 then Matches.update match._id, $set: gamestatus: 'gameInProgress'
							when 6 then Matches.update match._id, $set: gamestatus: 'postGame'