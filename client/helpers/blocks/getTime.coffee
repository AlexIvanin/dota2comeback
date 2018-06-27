UI.registerHelper 'getTime', (time) ->
	time = Number time
	if time?
		if (Date.now() - 60000) < time then 'Только что'
		else if (Date.now() - 3600000 * 3) < time
			moment(time).fromNow()
		else if (Date.now() - 3600000 * 24) < time
			moment(time).calendar()
		else
			moment(time).format 'll в HH:mm'
	else 'Никогда'

UI.registerHelper 'getTimeFromNow', (time) ->
	time = Number time

	if time?
		moment(time).fromNow()