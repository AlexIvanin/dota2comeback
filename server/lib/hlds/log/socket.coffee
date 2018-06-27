if Meteor.isServer
	@startLogSocket = ->
		ip = Config.get 'logSocketIP'
		port = Config.get 'logSocketPort'

		if ip and port
			Servers.log = new HLDS.log.socket address: ip, port: port

			Servers.log.on 'data', Meteor.bindEnvironment (data, remote) ->
				HLDS.log.parse data, (request) ->
					console.log request, remote
					if Config.get('serverIP') is remote.address
						remote.password = Config.get 'serverRcon'
						remote.id = request.id
						Matches.handleRequest request, remote

	Meteor.methods
		refreshLogSocket: ->
			if Roles.userIsInRole @userId, 'admin'
				startLogSocket()

	Meteor.startup ->
		EventEmitter = Npm.require('events').EventEmitter
		
		@Connection = (authorized) ->
			@authorized = authorized or null
			@socket = null
		
		Connection::__proto__ = EventEmitter::
		
		Connection::listen = (port, address, type, cb) ->
			self = @
			
			if typeof type is 'function'
				cb = type
				type = null
			
			if typeof address is 'function'
				cb = address
				address = null
			
			if typeof port is 'function'
				cb = port
				port = null
			
			@socket = dgram.createSocket type or 'udp4'
			
			@socket.bind port or 27017, address or '0.0.0.0', -> cb and cb()
			
			@socket.on 'message', (msg, remote) ->
				return if self.authorized.indexOf(remote.address) is -1 if self.authorized
				self.emit 'data', msg, remote
			
			@socket.on 'error', (err) -> self.emit 'error', err
		
		@HLDS.log.socket = (options) ->
			self = @
			
			@options = options or {}
			@connection = new Connection @options.authorized
			@connection.listen options.port, options.address, options.type
			@connection.on 'data', (data, remote) -> self.parse data, remote
			@connection.on 'error', (err) -> self.emit 'error', err
			
			@parse = (buffer, remote) -> self.emit 'data', buffer.toString('utf8', 0, buffer.length - 2), remote
			
			return @
		
		@HLDS.log.socket::__proto__ = EventEmitter::