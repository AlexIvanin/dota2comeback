UI.registerHelper 'getUser', (id) -> getUser id

UI.registerHelper 'isMyFriend', (userId) ->
	Meteor.users.findOne(_id: Meteor.userId(), 'profile.friends': _id: userId, accepted: on) and Meteor.users.findOne(_id: userId, 'profile.friends': _id: Meteor.userId(), accepted: on)

UI.registerHelper 'isRequesterFriend', (userId) ->
	Meteor.users.findOne(_id: userId, 'profile.friends': _id: Meteor.userId(), accepted: on) and Meteor.users.findOne(_id: Meteor.userId(), 'profile.friends': _id: userId, accepted: no)

UI.registerHelper 'isAccepterFriend', (userId) ->
	Meteor.users.findOne(_id: userId, 'profile.friends': _id: Meteor.userId(), accepted: no) and Meteor.users.findOne(_id: Meteor.userId(), 'profile.friends': _id: userId, accepted: on)

Template.user.events
	'click #addFriend': -> Meteor.call 'addFriend', @_id, (e, r) -> alert e if e

	'click #deleteFriend': -> Meteor.call 'deleteFriend', @_id, (e, r) -> alert e if e

	'click #acceptRequestFriend': -> Meteor.call 'acceptRequestFriend', @_id, (e, r) -> alert e if e

	'click #declineRequestFriend': -> Meteor.call 'declineRequestFriend', @_id, (e, r) -> alert e if e

	'click #abortRequestFriend': -> Meteor.call 'abortRequestFriend', @_id, (e, r) -> alert e if e

	'input #selectedMoneyUnitpay': (e) -> Session.set 'selectedMoneyUnitpay', Number e.currentTarget.value

	'input #selectedMoneyWebmoney': (e) -> Session.set 'selectedMoneyWebmoney', Number e.currentTarget.value

	'input #selectedMoneyRobokassa': (e) -> Session.set 'selectedMoneyRobokassa', Number e.currentTarget.value

	'click #robokassaGetLink': ->
		Meteor.call 'getRobokassaLink', Session.get('selectedMoneyRobokassa'), (e, link) ->
			document.location.href = link

	'change #selectedPurse': (e) -> Session.set 'selectedPurse', e.currentTarget.value

	'input #selectedMoneyOut': (e) -> Session.set 'selectedMoneyOut', Number e.currentTarget.value

	'click .btn-pay-out': (e) ->
		Meteor.call 'payOutRequest', $('#selectedPurse').val(), Number($('#selectedMoneyOut').val()), (e, r) ->
			if e
				alert e
			else
				alert 'Заявка на вывод средств отправлена администрации и в ближайшее время будет рассмотрена'
				$('#moneyOutModal').modal 'hide'


Template.userSettings.events
	'change #inputMoney': (e) -> Meteor.users.update @_id, $set: 'profile.money': Number e.currentTarget.value
	'input #inputName': (e) -> Meteor.users.update @_id, $set: 'profile.name': e.currentTarget.value
	'input #inputEmail': (e) -> Meteor.users.update @_id, $set: 'profile.email': e.currentTarget.value
	'input #inputWM': (e) -> Meteor.users.update @_id, $set: 'profile.wm': e.currentTarget.value
	'input #inputQiwi': (e) -> Meteor.users.update @_id, $set: 'profile.qiwi': e.currentTarget.value

	'change #selectRole': (e) ->
		if e.currentTarget.value is 'admin'
			Meteor.call 'setUserRole', @_id, 'admin'
		else if e.currentTarget.value is 'user'
			Meteor.call 'setUserRole', @_id


Template.user.rendered = ->
	Session.set 'selectedMoneyUnitpay', $('#selectedMoneyUnitpay').val()
	Session.set 'selectedPurse', $('#selectedPurse').val()
	Session.set 'selectedMoneyOut', Number $('#selectedMoneyOut').val()

Template.user.selectedMoneyUnitpay = -> Session.get 'selectedMoneyUnitpay'
Template.user.selectedMoneyWebmoney = -> Session.get 'selectedMoneyWebmoney'
Template.user.selectedMoneyRobokassa = -> Session.get 'selectedMoneyRobokassa'
Template.user.selectedPurse = -> Session.get 'selectedPurse'
Template.user.hasMoneyWM = -> Meteor.user().profile.money >= 50
Template.user.hasMoneyQIWI = -> Meteor.user().profile.money >= 200 * 1.019
Template.user.selectedMoneyValid = ->
	if Session.get('selectedPurse') is 'qiwi'
		return Session.get('selectedMoneyOut') * 1.019 <= Meteor.user().profile.money
	else if Session.get('selectedPurse') is 'wm'
		return Session.get('selectedMoneyOut') <= Meteor.user().profile.money


Template.user.selectedMoneyOutQiwi = -> Session.get('selectedMoneyOut') * 1.019

Template.userTickets.events
	'click .btn-send-ticket-reply': ->
		message = $('#reply').val()

		if message
			Meteor.call 'ticketsAddReply', @_id, message
			$('#reply').val ''
		else
			alert 'Введите сообщение для ответа'