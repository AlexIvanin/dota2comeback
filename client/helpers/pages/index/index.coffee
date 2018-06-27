hasMoreMatchesFinished = -> Config.get('matchesTotalCount') - Matches.find(status: 'finished').count() > 0

Template.index.helpers
	hasMoreMatchesFinished: hasMoreMatchesFinished

Template.index.rendered = ->
	Deps.autorun ->
		Meteor.subscribe 'matchesFinishedList', Session.get 'matchesFinishedLimit'

	Session.setDefault 'matchesFinishedLimit', 20

	window.onscroll = (_.throttle ->
		if (window.innerHeight + window.scrollY) >= document.getElementById('wrap').offsetHeight * .8
			if hasMoreMatchesFinished()
				matchesLimit = Session.get 'matchesFinishedLimit'
				Session.set 'matchesFinishedLimit', matchesLimit + 25
	, 500)

	$('[data-toggle=tooltip]').tooltip()

Template.matchCreateModal.events
	'click .set-gametype-money': (e) ->
		$('.set-gametype-items').removeClass 'active'
		$('.set-gametype-money').addClass 'active'
		$('.match-type-items').hide()
		$('.match-type-money').fadeIn 500

	'click .set-gametype-items': (e) ->
		$('.set-gametype-money').removeClass 'active'
		$('.set-gametype-items').addClass 'active'
		$('.match-type-money').hide()
		$('.match-type-items').fadeIn 500
