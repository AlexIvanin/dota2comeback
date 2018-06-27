@moneyRequests = new Meteor.Collection 'moneyRequests'

moneyRequests.before.find excludeCounter

moneyRequests.allow
	insert: (userId) -> Roles.userIsInRole userId, 'admin'
	update: (userId) -> Roles.userIsInRole userId, 'admin'
	remove: (userId) -> Roles.userIsInRole userId, 'admin'

Meteor.publish 'adminPayOuts', (limit) ->
	@unblock()

	if @userId and Roles.userIsInRole @userId, 'admin'
		self = @

		handle = moneyRequests.find({}, sort: date: -1).observeChanges 
			added: (id, fields) ->
				self.added 'moneyRequests', id, fields

				user = Meteor.users.findOne fields.userId,
					fields: 'services.resume': 0

				if user
					self.added 'users', user._id, user

			changed: (id, fields) -> self.changed 'moneyRequests', id, fields
			removed: (id) -> self.removed 'moneyRequests', id

		@onStop -> handle.stop()
		@ready()
	else @ready()

Meteor.methods
	adminAcceptPayOut: (id) ->
		@unblock()
		if @userId and Roles.userIsInRole @userId, 'admin'
			req = moneyRequests.findOne id

			if req
				user = Meteor.users.findOne req.userId

				if user
					moneyRequests.update id, $set: status: 'payed'

	adminDeclinePayOut: (id, reason) ->
		@unblock()
		if @userId and Roles.userIsInRole @userId, 'admin'
			req = moneyRequests.findOne id

			if req
				user = Meteor.users.findOne req.userId

				if user
					if req.purseType is 'qiwi'
						Meteor.users.update user._id, $inc: 'profile.money': req.money * 1.019
					else
						Meteor.users.update user._id, $inc: 'profile.money': req.money

					moneyRequests.update id, $set: status: 'notpayed', reason: reason


	payOutRequest: (purse, money) ->
		@unblock()
		if @userId
			check purse, String
			check money, Number

			if Meteor.user().allowPayOut()
				userMoney = Meteor.user().profile.money

				if money <= userMoney
					if purse is 'wm'
						if Meteor.user().profile.wm
							if money >= 50
								Meteor.users.update @userId, $inc: 'profile.money': -money

								moneyRequests.insert
									_id: String incrementCounter moneyRequests
									date: Date.now()
									userId: @userId
									money: money
									purseType: purse
									purse: Meteor.user().profile.wm
									status: 'wait'


					else if purse is 'qiwi'
						if Meteor.user().profile.qiwi
							if money >= 200
								Meteor.users.update @userId, $inc: 'profile.money': -money * 1.019

								moneyRequests.insert
									_id: String incrementCounter moneyRequests
									date: Date.now()
									userId: @userId
									money: money
									purseType: purse
									purse: Meteor.user().profile.qiwi
									status: 'wait'
