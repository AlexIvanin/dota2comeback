Template.match.events
	'click .btn-take-slot-good': (e, t) ->
		if t.data.hasPassword
			password = prompt 'Введите пароль'

			if password
				Meteor.call 'matchTakeSlot', @_id, 'good', password, (e) -> alert e if e
		else
			Meteor.call 'matchTakeSlot', @_id, 'good', (e) -> alert e if e

	'click .btn-take-slot-bad': (e, t) ->
		if t.data.hasPassword
			password = prompt 'Введите пароль'

			if password
				Meteor.call 'matchTakeSlot', @_id, 'bad', password, (e) -> alert e if e
		else
			Meteor.call 'matchTakeSlot', @_id, 'bad', (e) -> alert e if e

	'click .btn-leave-slot': ->
		Meteor.call 'matchLeaveSlot', (e) ->
			if e then alert e
			else Router.go 'index'

	'click #btn-ready': -> Meteor.call 'matchReady', (e) -> if e then alert e

	'click .btn-remove': ->
		if confirm 'Вы действительно хотите удалить матч?'
			Meteor.call 'removeMatch', @_id