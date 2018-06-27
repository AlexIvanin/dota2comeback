Router.plugin 'loading', loadingTemplate: 'loading'
Router.plugin 'dataNotFound', notFoundTemplate: 'notFound'

Router.configure
	layoutTemplate: 'layout'
	notFoundTemplate: 'notFound'
	loadingTemplate: 'loading'
	fastRender: on

Router.map ->
	@route 'help'
	@route 'contact'
	@route 'contacts'
	@route 'about'
	@route 'donate'

	@route 'news',
		fastRender: on
		waitOn: -> Meteor.subscribe 'news'
		data: news: -> News.find {}, sort: date: -1

	@route 'novelty',
		path: '/news/:id'
		onAfterAction: ->
			if @ready()
				@render 'notFound' unless @data()
		waitOn: -> [
			Meteor.subscribe 'novelty', @params.id
			Meteor.subscribe 'noveltyComments', @params.id
		]
		data: -> News.findOne @params.id
		fastRender: on

	@route 'match',
		path: '/match/:_id',
		waitOn: -> [
			Meteor.subscribe 'match', @params._id
			Meteor.subscribe 'chat'
			Meteor.subscribe 'heroes'
		]
		onAfterAction: ->
			if @ready()
				@render 'notFound' unless @data()
				Session.set('currentMatchID', @params._id)
		data: -> Matches.findOne @params._id
		fastRender: on

	@route 'user',
		path: '/user/:_id'
		onAfterAction: ->
			if @ready()
				@render 'notFound' unless @data()
				Session.set 'currentShowUserID', @params._id
		waitOn: -> Meteor.subscribe 'user', @params._id
		data: -> getUser @params._id
		fastRender: on

	@route 'top',
		fastRender: on
		waitOn: -> Meteor.subscribe 'top'
		data:
			users: -> Meteor.users.find {'profile.rating.place': $exists: on}, sort: 'profile.rating.place': 1

	@route 'userTickets',
		path: '/user/:userId/tickets/:ticketId'
		onAfterAction: ->
			if @ready()
				@render 'notFound' unless @data()
		waitOn: -> Meteor.subscribe 'ticket', @params.ticketId
		data: -> Tickets.findOne @params.ticketId
		fastRender: on

	@route 'user/settings',
		path: '/user/:_id/settings'
		onAfterAction: ->
			if @ready()
				@render 'notFound' unless @data()
				@render 'forbidden' unless Meteor.user()
				unless Number(@params._id) is Meteor.user().id
					unless Roles.userIsInRole Meteor.userId(), 'admin'
						@render 'forbidden' 
				Session.set 'currentShowUserID', @params._id
		waitOn: -> Meteor.subscribe 'user', @params._id
		data: -> getUser @params._id
		fastRender: on

	@route 'profile',
		action: ->
			if Meteor.user()
				Router.go "/user/#{Meteor.user().id}"
			else
				@render 'notFound'

	@route 'admin',
		path: 'admin/stats'

	@route 'admin/settings',
		fastRender: on
		data:
			roles: -> Roles.getAllRoles()

	@route 'admin/news'
	@route 'admin/users',
		fastRender: on
		waitOn: -> Meteor.subscribe 'adminUsers'
		data:
			users: -> Meteor.users.find {}, sort: id: -1


	@route 'admin/events',
		fastRender: on
		waitOn: -> [
			Meteor.subscribe 'payments'
			Meteor.subscribe 'visits'
		]
		data:
			payments: -> Events.find {isPayment: on}, sort: date: -1
			visits: -> Events.find {isVisit: on}, sort: date: -1

	@route 'admin/tickets',
		fastRender: on
		waitOn: -> [
			Meteor.subscribe 'adminTicketsOpen'
			Meteor.subscribe 'adminTicketsClosed'
		]
		data:
			ticketsOpen: -> Tickets.find {closed: no}, sort: date: -1
			ticketsClosed: -> Tickets.find {closed: on}, sort: date: -1

	@route 'adminTicket',
		path: 'admin/tickets/:_id'
		onAfterAction: ->
			if @ready()
				@render 'notFound' unless @data()
		waitOn: -> Meteor.subscribe 'adminTicket', @params._id
		data: -> Tickets.findOne @params._id
		fastRender: on


	@route 'admin/moneyOut',
		fastRender: on
		waitOn: -> Meteor.subscribe 'adminPayOuts'
		data:
			payOuts: -> moneyRequests.find {}, sort: date: -1

	@route 'webmoney/fail'

	@route 'index',
		path: '/'
		fastRender: on
		data:
			matchesInGame: -> Matches.find {status: 'inGame'}, sort: dateCreate: -1
			matchesInSearch: -> Matches.find {status: 'inSearch'}, sort: dateStarted: -1
			matchesFinished: -> Matches.find {status: 'finished'}, sort: dateFinished: -1
			heroes: -> Heroes.find {}, sort: name: 1
		onBeforeAction: ->
			ref = @params.query.ref

			if ref?
				Session.set 'ref', ref
				Meteor.call 'setRef', ref
			@next()
		waitOn: -> [
			Meteor.subscribe 'matchesInSearchList'
			Meteor.subscribe 'matchesInGameList'
			Meteor.subscribe 'heroes'
			Meteor.subscribe 'chat'
			Meteor.subscribe 'lastUser'
		]