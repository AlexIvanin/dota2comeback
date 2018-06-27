init = no

Events.find().observeChanges 
	added: (id, fields) ->
		if init
			if fields.isPayment
				money = Number fields.params.profit or fields.params.LMI_PAYMENT_AMOUNT or fields.params.OutSum
				payUser = Meteor.users.findOne fields.userId

				if money > 0
					ref = Meteor.users.findOne payUser.profile.ref

					if ref and payUser.payments().count() is 1
						Meteor.users.update payUser._id, $inc: 'profile.money': 10

init = on