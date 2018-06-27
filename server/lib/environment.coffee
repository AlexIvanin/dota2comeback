@excludeCounter = (userId, selector, options) ->
	if typeof selector is 'string'
		selector =
			_id: selector
			next_val:
				$exists: no

	if typeof selector is 'object'
		selector.next_val = $exists: no

SyncedCron.options =
	collectionName: 'CronHistory'
	collectionTTL: 172800
	log: no
	utc: no

if Meteor.AppCache?
	Meteor.AppCache.config onlineOnly: ['/public/']

unless Config.get('money')?
	Config.set 'money', 0, no

Config.set 'hostname', Meteor.absoluteUrl().replace(/http:\/\/|https:\/\//g,'').replace(/\//g,''), true

if Config.get('steamApiKey')?
	ServiceConfiguration = Package['service-configuration'].ServiceConfiguration

	unless ServiceConfiguration.configurations.findOne(service: 'steam')
		ServiceConfiguration.configurations.insert
			service: 'steam'
			apiKey: Config.get('steamApiKey')

updateUsers = ->
	Config.set 'usersCount', Meteor.users.find().count(), on
	Config.set 'usersOnServersCount', Meteor.users.find(onServer: on).count(), on

updateMatches = ->
	Config.set 'matchesCount', Matches.find(status: 'finished', aborted: no).count(), on
	Config.set 'matchesTotalCount', Matches.find(status: 'finished').count(), on
	Config.set 'matchesInGameCount', Matches.find(status: 'inGame').count(), on

updateTickets = ->
	Config.set 'ticketsOpenCount', Tickets.find(closed: no).count(), no
updatePayOuts = ->
	Config.set 'payOutsCount', moneyRequests.find(status: 'wait').count(), no

Meteor.startup ->
	Meteor.isProduction = process.env.NODE_ENV is 'production'
	Meteor.isDevelopment = process.env.NODE_ENV is 'development'
	Meteor.path = if Meteor.isProduction then "#{process.env.PWD}/programs/server" else process.env.PWD

	SyncedCron.start()

	init = no

	Matches.find().observeChanges
		added: -> updateMatches() if init
		changed: -> updateMatches()
		removed: -> updateMatches()

	Meteor.users.find().observeChanges
		added: -> updateUsers() if init
		changed: -> updateUsers()
		removed: -> updateUsers()

	Tickets.find(closed: no).observeChanges 
		added: -> updateTickets() if init
		changed: -> updateTickets()
		removed: -> updateTickets()

	moneyRequests.find(status: 'wait').observeChanges 
		added: -> updatePayOuts() if init
		changed: -> updatePayOuts()
		removed: -> updatePayOuts()

	init = on

	Meteor.setTimeout ->
		updateMatches()
		updateUsers()
		updateTickets()
		updatePayOuts()
		updateUsersTop()
	, 0