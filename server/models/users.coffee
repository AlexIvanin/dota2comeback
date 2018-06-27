@updateUsersTop = ->
	Meteor.users.update {},
		$unset:
			'profile.rating.place': on
	,
		multi: on

	Meteor.users.find({}, limit: 100, sort: 'profile.rating.one.score': -1, 'profile.rating.five.score': -1).forEach (user, index, cursor) ->
		i = _.extend user, index: index
		i.index++
		Meteor.users.update user._id, $set: 'profile.rating.place': i.index

SyncedCron.add
	name: 'Reset users top'
	schedule: (parser) -> parser.text 'every month'
	job: ->
		updateUsersTop()

		Meteor.users.update {},
			$set:
				'profile.rating.one.score': 500
				'profile.rating.five.score': 500
		,
			multi: on