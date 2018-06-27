if Meteor.isServer
	Meteor.startup ->
		HLDS.log.parse = (line,callback) ->
			if Buffer.isBuffer line
				line = line.toString 'utf8'
			startingpoint = line.indexOf 'L '
			if startingpoint isnt -1
				line = line.substring(startingpoint).replace(/(\r\n|\n|\r|\u0000)/gm,"").trim()
				parseutils.parseLineInfo line, (result) -> callback result
			else callback no

		HLDS.log.parse.isSourceTV = (player) -> player.id is 2 and player.name is 'SourceTV' and player.steamid is 'BOT'

		@parseutils = {}

		parseArgs = (args) -> args.match /[(]([^"]|\\")+ ["]([^"]|\\")+["][)]/g

		parseutils.parseTime = (line) ->
			result = line.match /^L (\d\d)\/(\d\d)\/(\d\d\d\d) - (\d\d):(\d\d):(\d\d): /
			return false if not result or result.length is 0
			new Date parseInt(result[3], 10), parseInt(result[1], 10) - 1, parseInt(result[2], 10), parseInt(result[4], 10), parseInt(result[5], 10), parseInt(result[6], 10), 0

		parseutils.parsePlayer = (line) ->
			result = line.match /(.+)<(\d+)><(.+)><?(.+)>/
			return false if not result or result.length is 0
			name: result[1]
			id: parseInt result[2], 10
			steamid: result[3]
			team: result[4]

		parseutils.parseLineInfo = (line, callback) ->
			result = line.match /^L \d\d\/\d\d\/\d\d\d\d - \d\d:\d\d:\d\d: World triggered ["](.+)["] (.+)$/
			return callback(type: "worldtrigger", trigger: result[1], args: parseArgs(result[2])) if result?

			result = line.match /^L \d\d\/\d\d\/\d\d\d\d - \d\d:\d\d:\d\d: World triggered ["](.+)["]$/
			return callback(type: "worldtrigger", trigger: result[1]) if result?

			result = line.match /^L \d\d\/\d\d\/\d\d\d\d - \d\d:\d\d:\d\d: rcon from ["](.+)[:](\d+)["][:] command ["](.+)["]$/
			return callback(type: "rcon", address: result[1], port: parseInt(result[2], 10), command: result[3]) if result?

			result = line.match /^L \d\d\/\d\d\/\d\d\d\d - \d\d:\d\d:\d\d: "(.+)" picked up item ["](.+)["]$/
			return callback(type: "picked up", player: parseutils.parsePlayer(result[1]), item: result[2]) if result?

			result = line.match /^L \d\d\/\d\d\/\d\d\d\d - \d\d:\d\d:\d\d: ["](.+)["] committed suicide with ["](.+)["] [(]attacker_position ["](.+) (.+) (.+)["][)]$/
			return callback(type: "suicide", player: parseutils.parsePlayer(result[1]), with: result[2], attacker_position: [parseInt(result[3]), parseInt(result[4]), parseInt(result[5])]) if result?

			result = line.match /^L \d\d\/\d\d\/\d\d\d\d - \d\d:\d\d:\d\d: "(.+)" changed role to ["](.+)["]$/
			return callback(type: "changed role", player: parseutils.parsePlayer(result[1]), role: result[2]) if result?

			result = line.match /^L \d\d\/\d\d\/\d\d\d\d - \d\d:\d\d:\d\d: "(.+)" connected, address ["](.+):(.+)["]$/
			return callback(type: "connected", player: parseutils.parsePlayer(result[1]), ip: result[2], port: parseInt(result[3])) if result?

			result = line.match /^L \d\d\/\d\d\/\d\d\d\d - \d\d:\d\d:\d\d: "(.+)" STEAM USERID validated$/
			return callback(type: "STEAM USERID validated", player: parseutils.parsePlayer(result[1])) if result?

			result = line.match /^L \d\d\/\d\d\/\d\d\d\d - \d\d:\d\d:\d\d: "(.+)" disconnected [(]reason "(.+)"[)]$/
			return callback(type: "disconnected", player: parseutils.parsePlayer(result[1]), reason: result[2]) if result?

			result = line.match /^L \d\d\/\d\d\/\d\d\d\d - \d\d:\d\d:\d\d: "(.+)" joined team ["](.+)["]$/
			return callback(type: "joined team", player: parseutils.parsePlayer(result[1]), team: result[2]) if result?

			result = line.match /^L \d\d\/\d\d\/\d\d\d\d - \d\d:\d\d:\d\d: "(.+)" entered the game$/
			return callback(type: "entered the game", player: parseutils.parsePlayer(result[1])) if result?

			result = line.match /^L \d\d\/\d\d\/\d\d\d\d - \d\d:\d\d:\d\d: Started map "(.+)" [(]CRC "(.+)"[)]$/
			return callback(type: "startedMap", map: result[1], crc: result[2]) if result?

			result = line.match /^L \d\d\/\d\d\/\d\d\d\d - \d\d:\d\d:\d\d: Team "(.+)" current score "(\d+)" with "(\d+)" players$/
			return callback(type: "currentScore", team: result[1], score: parseInt(result[2]), players: parseInt(result[3])) if result?

			result = line.match /^L \d\d\/\d\d\/\d\d\d\d - \d\d:\d\d:\d\d: Team "(.+)" final score "(\d+)" with "(\d+)" players$/
			return callback(type: "finalScore", team: result[1], score: parseInt(result[2]), players: parseInt(result[3])) if result?

			result = line.match /^L \d\d\/\d\d\/\d\d\d\d - \d\d:\d\d:\d\d: "(.+)" spawned as ["](.+)["]$/
			return callback(type: "spawned", player: parseutils.parsePlayer(result[1]), role: result[2]) if result?

			result = line.match /^L \d\d\/\d\d\/\d\d\d\d - \d\d:\d\d:\d\d: "(.+)" say ["](.+)["]$/
			return callback(type: "say", player: parseutils.parsePlayer(result[1]), text: result[2]) if result?

			result = line.match /^L \d\d\/\d\d\/\d\d\d\d - \d\d:\d\d:\d\d: "(.+)" say_team ["](.+)["]$/
			return callback(type: "say_team", player: parseutils.parsePlayer(result[1]), text: result[2]) if result?

			result = line.match /^L \d\d\/\d\d\/\d\d\d\d - \d\d:\d\d:\d\d: "(.+)" position_report (.+)$/
			return callback(type: "position_report", player: parseutils.parsePlayer(result[1]), text: parseArgs(result[2])) if result?

			result = line.match /^L \d\d\/\d\d\/\d\d\d\d - \d\d:\d\d:\d\d: "(.+)" killed "(.+)" with ["](.+)["]/
			return callback(type: "kill", player: parseutils.parsePlayer(result[1]), killed: parseutils.parsePlayer(result[2]), weapon: result[3]) if result?

			result = line.match /^L \d\d\/\d\d\/\d\d\d\d - \d\d:\d\d:\d\d: "(.+)" triggered ["](.+)["]\n\u0000$/
			return callback(type: "trigger", player: parseutils.parsePlayer(result[1]), event: result[2]) if result?

			result = line.match /^L \d\d\/\d\d\/\d\d\d\d - \d\d:\d\d:\d\d: MATCH_END: (.+), MATCH_ID: (.+)/
			return callback(type: 'MATCH_END', id: result[2], winTeam: if result[1] is '2' then 'good' else 'bad') if result?

			result = line.match /^L \d\d\/\d\d\/\d\d\d\d - \d\d:\d\d:\d\d: GAME_STATE: (.+), MATCH_ID: (.+)/
			return callback(type: 'GAME_STATE', id: result[2], state: Number(result[1])) if result?

			result = line.match /^L \d\d\/\d\d\/\d\d\d\d - \d\d:\d\d:\d\d: MATCH_ABORT, MATCH_ID: (.+)/
			return callback(type: 'MATCH_ABORT', id: result[1]) if result?

			result = line.match /^L \d\d\/\d\d\/\d\d\d\d - \d\d:\d\d:\d\d: server_message: ["](.+)["]/
			return callback(type: 'server_message', message: result[1]) if result?