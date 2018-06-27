moment.locale 'ru'

Deps.autorun ->
	ref = Session.get 'ref'

	if Meteor.user() and ref
		Meteor.call 'setRef', ref