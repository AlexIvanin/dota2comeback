Template.contact.events
	'click button': (e, t) ->
		urgency = $('#ticketUrgency').val()
		theme = $('#ticketTheme').val()
		desc = $('#ticketDescription').val()

		if urgency and theme and desc
			$(e.currentTarget).button 'loading'

			Meteor.call 'ticketAdd', urgency, theme, desc, (err, r) ->
				if err
					alert err
				else
					$(e.currentTarget).button 'reset'
					$('#ticketTheme').val ''
					$('#ticketDescription').val ''
					alert 'Ваш тикет отправлен администрации проекта. В скором времени вы получите ответ на ваш тикет.'
					Router.go "/user/#{Meteor.user().id}/tickets/#{r}"
		else alert 'Не все поля заполнены'