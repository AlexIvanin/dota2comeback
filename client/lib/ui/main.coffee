UI.registerHelper 'config', (key) -> Config.get key
UI.registerHelper 'session', (key) -> Session.get key
UI.registerHelper 'store', (key) -> ReactiveStore.get key

UI.registerHelper 'usersOnlineCount', ->
	Meteor.users.find('status.online': on).count()