Template.adminUsers.hasMoreUsers = -> Config.get('usersCount') - Meteor.users.find({}, sort: createdAt: -1).count() > 0

Template.adminUsers.rendered = ->
	Deps.autorun -> Meteor.subscribe 'adminUsers', Session.get 'adminUsersLimit'

	Session.setDefault 'adminUsersLimit', 25

	window.onscroll = (_.throttle ->
		if (window.innerHeight + window.scrollY) >= document.getElementById('wrap').offsetHeight * .8
			if Template.adminUsers.hasMoreUsers()
				usersLimit = Session.get 'adminUsersLimit'
				Session.set 'adminUsersLimit', usersLimit + 25
	, 500)

Template.admin.money = -> Config.get 'money'

Template.admin.hddLoad = -> Config.get 'hdd'

Template.admin.cpuLoad = ->
	stats = Config.get 'stats'

	if stats
		avg = getAverageOfArray(stats.cpu) * 100
		return avg.toFixed(0)

Template.admin.ramLoad = ->
	stats = Config.get 'stats'

	if stats
		p = stats.memory.process * 100
		s = stats.memory.system * 100
		avg = p + s

		return avg.toFixed(0)

Template.adminSettings.events
	'input #inputTitle': (e) -> Config.set 'title', e.currentTarget.value, on
	'input #inputBrand': (e) -> Config.set 'brand', e.currentTarget.value, on
	'input #inputFooter': (e) -> Config.set 'footer', e.currentTarget.value, on
	'input #inputSteamApiKey': (e) -> Config.set 'steamApiKey', e.currentTarget.value, no
	'input #inputUnitpayKey': (e) -> Config.set 'unitpayKey', e.currentTarget.value, no
	'input #inputWebmoneyKey': (e) -> Config.set 'webmoneyKey', e.currentTarget.value, no
	'input #inputWebmoneyPurse': (e) -> Config.set 'webmoneyPurse', e.currentTarget.value, on

	'input #inputRobokassaLogin': (e) -> Config.set 'robokassaLogin', e.currentTarget.value, no
	'input #inputRobokassaKey1': (e) -> Config.set 'robokassaKey1', e.currentTarget.value, no
	'input #inputRobokassaKey2': (e) -> Config.set 'robokassaKey2', e.currentTarget.value, no

	'click #setYandexMetrika': -> Config.set 'yandexMetrika', $('#setYandexMetrika').prop('checked'), on
	'click #setLiveinternet': -> Config.set 'liveInternet', $('#setLiveinternet').prop('checked'), on
	'click #setWebmoney': -> Config.set 'webmoneyImg', $('#setWebmoney').prop('checked'), on

	'click #setUnitpayOn': -> Config.set 'unitpayOn', $('#setUnitpayOn').prop('checked'), on
	'click #setWebmoneyOn': -> Config.set 'webmoneyOn', $('#setWebmoneyOn').prop('checked'), on
	'click #setRobokassaOn': -> Config.set 'robokassaOn', $('#setRobokassaOn').prop('checked'), on

	'input #inputPercent10r': (e) -> Config.set 'percent10r', e.currentTarget.value, on
	'input #inputPercent25r': (e) -> Config.set 'percent25r', e.currentTarget.value, on
	'input #inputPercent100r': (e) -> Config.set 'percent100r', e.currentTarget.value, on
	'input #inputPercent300r': (e) -> Config.set 'percent300r', e.currentTarget.value, on
	'input #inputMinMoney': (e) -> Config.set 'minMoney', e.currentTarget.value, on

	'click #setAllowMoneyIn': -> Config.set 'allowMoneyIn', $('#setAllowMoneyIn').prop('checked'), on
	'click #setAllowMoneyOut': -> Config.set 'allowMoneyOut', $('#setAllowMoneyOut').prop('checked'), on

	'click .btn-save-server-settings': ->
		Config.set 'serverIP', $('#inputServerIP').val(), on
		Config.set 'serverPortSSH', $('#inputServerPortSSH').val(), no
		Config.set 'serverLoginSSH', $('#inputServerLoginSSH').val(), no
		Config.set 'serverPasswordSSH', $('#inputServerPasswordSSH').val(), no
		Config.set 'serverPath', $('#inputServerPath').val(), no
		Config.set 'serverRcon', $('#inputServerRcon').val(), no

		logaddress = $('#inputLogAddress').val()

		if logaddress isnt "#{Config.get('logSocketIP')}:#{Config.get('logSocketPort')}"
			match = logaddress.match /(.*):(.*)/

			if match
				Config.set 'logSocketIP', match[1], no
				Config.set 'logSocketPort', Number(match[2]), no
			else
				Config.set 'logSocketIP', undefined, no
				Config.set 'logSocketPort', undefined, no

			Meteor.call 'refreshLogSocket'

Template.adminMoneyOut.events
	'click .btn-decline-payout': ->
		if confirm 'Вы действительно хотите отклонить заявку на вывод?'
			Meteor.call 'adminDeclinePayOut', @_id, prompt 'Введите причину отказа'
	'click .btn-accept-payout': -> Meteor.call 'adminAcceptPayOut', @_id

Template.adminNews.events
	'click .btn-add-novelty': ->
		novelty =
			description: CKEDITOR.instances.inputDescription.getData()
			text: CKEDITOR.instances.inputText.getData()
			title: $('#inputTitle').val()
			image: $('#inputImage').val()
			oneComment: $('#setOneComment').prop 'checked'

		Meteor.call 'newsAddNovelty', novelty, (e, r) -> if e then alert(e) else Router.go "/news/#{r}"

Template.adminTicket.events
	'click .btn-send-ticket-reply': ->
		message = $('#reply').val()
		closeTicket = $('#setCloseTicket').prop 'checked'

		if message
			Meteor.call 'ticketsAddAdminReply', @_id, message, closeTicket
			$('#reply').val ''
		else
			alert 'Введите сообщение для ответа'

Template.adminNews.rendered = ->
	CKEDITOR.replace 'inputDescription'
	CKEDITOR.replace 'inputText'