Template.matchCreateModal.events
	'click #btn-create-match': ->
		params =
			type: Number $('#selectType').val()
			money: Number $('#selectMoney').val()
			mode: Number $('#selectMode').val()
			kills: Number $('#selectMaxKills').val()
			towers: Number $('#selectMaxTowers').val()
			team: $('#selectTeam').val()
			heroID: $('#selectedHero').val()
			withoutRunes: $('#setRunes').prop 'checked'
			withoutNeutrals: $('#setNeutrals').prop 'checked'
			password: $('#inputPassword').val()
			creeps:
				top: $('#creeps-top').prop 'checked'
				mid: $('#creeps-mid').prop 'checked'
				bot: $('#creeps-bot').prop 'checked'
			tv_enable: $('#setTV').prop 'checked'

		if $('#setPassword').prop('checked')
			unless $('#inputPassword').val()
				alert 'Введите пароль!'
				return

		Meteor.call 'createMatch', params, (e, r) ->
			if e then alert e
			else
				$('#matchCreateModal').modal 'hide'
				Router.go "/match/#{r}"

	'input #selectMoney': (e) -> Session.set 'selectedMoney', e.currentTarget.value

	'change #selectMode': (e) -> Session.set 'midOnlySelected', e.currentTarget.value is '11'

	'change #selectType': (e) ->
		Session.set 'moreTwoSlots', e.currentTarget.value > 1
		Session.set 'moreFourSlots', e.currentTarget.value > 2
		Session.set 'moreSixSlots', e.currentTarget.value > 3
		Session.set 'midOnlySelected', $('#selectMode').val() is '11'

	'change #setPassword': (e) -> Session.set 'settedPassword', e.currentTarget.checked

	'click .map-checkbox > input[type=checkbox]': (e) ->
		if $('.map-checkbox').find('input:checkbox:not(:checked)').length == 3
			e.stopPropagation()
			return no

Template.matchCreateModal.helpers
	selectedMidOnly: -> Session.get 'midOnlySelected'
	moreTwoSlots: -> Session.get 'moreTwoSlots'
	moreFourSlots: -> Session.get 'moreFourSlots'
	moreSixSlots: -> Session.get 'moreSixSlots'
	selectedMoneyValid: -> Session.get('selectedMoney') >= 10
	settedPassword: -> Session.get 'settedPassword'
	matchWinMoney: -> mathWinMoney Session.get 'selectedMoney'
	userHasMoney: -> Session.get('selectedMoney') <= Meteor.user().profile.money

Template.matchCreateModal.rendered = ->
	Session.set 'selectedMoney', $('#selectMoney').val()
	Session.set 'moreTwoSlots', $('#selectType').val() > 1
	Session.set 'moreFourSlots', $('#selectType').val() > 2
	Session.set 'moreSixSlots', $('#selectType').val() > 3
	Session.set 'settedPassword', $('#setPassword').prop('checked')
	Session.set 'midOnlySelected', $('#selectMode').val() is '11'

Template.matchCreateModal.created = ->
	Session.set 'selectedMoney', $('#selectMoney').val()
	Session.set 'moreTwoSlots', $('#selectType').val() > 1
	Session.set 'moreFourSlots', $('#selectType').val() > 2
	Session.set 'moreSixSlots', $('#selectType').val() > 3
	Session.set 'settedPassword', $('#setPassword').prop('checked')
	Session.set 'midOnlySelected', $('#selectMode').val() is '11'