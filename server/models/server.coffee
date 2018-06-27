@Servers =
	start: (match) ->
		if match
			playersTextFile = ""
			localPath = "/var/www/dota2comeback.com/assets/#{match._id}.ini"
			port = Config.get 'lastUsedPort'
			ip = Config.get 'serverIP'

			if port >= 27014
				Config.set 'lastUsedPort', 27001
				port = 27001
			else
				Config.set 'lastUsedPort', port + 2
				port = port + 2

			match.good.members.forEach (member) ->
				playersTextFile += "#{Meteor.users.findOne(member._id).services.steam.steamID2} 2\n"

			match.bad.members.forEach (member) ->
				playersTextFile += "#{Meteor.users.findOne(member._id).services.steam.steamID2} 3\n"

			fs.writeFileSync localPath, playersTextFile, mode: 511

			request = "cmd /c cd C:#{Config.get('serverPath')} && cmd /c srcds.exe -console -game dota"
			request += " +sv_hibernate_when_empty 0"
			request += " +hostname CB-Match##{match._id}"
			request += " +dota_wait_for_players_to_load 1"
			request += " +dota_wait_for_players_to_load_count #{match.realMembersCount()}"
			request += " +dota_wait_for_players_to_load_timeout 300"
			request += " +dota_force_gamemode #{match.mode}"
			request += " -port #{port} -ip #{ip}"
			request += " +ip #{ip}"
			request += " +net_public_adr #{ip}"
			request += " +map dota +rcon_password #{Config.get('serverRcon')}"
			request += " +log on +logaddress_add #{Config.get('logSocketIP')}:#{Config.get('logSocketPort')}"

			for lane of match.creeps
				if match.creeps[lane] is no
					request += " +dota_disable_#{lane}_lane 1"

			if match.tv_enable
				request += " +tv_enable 1 +tv_port #{port - 1} +tv_name TV-CB-Match##{match._id} +tv_secret_code 0 +tv_relay_secret_code 0 +tv_dispatchmode 0 +tv_autorecord 1"
				if match.type is 1
					request += " +tv_delay 0"

			if match.heroID
				request += " +set_hero #{match.hero().className}"

			request += " +set_match_id #{match._id}"
			request += " +set_max_towers #{match.towers}"
			request += " +set_max_kills #{match.kills}"
			request += " +set_runes #{Number(!match.withoutRunes)}"
			request += " +set_neutrals #{Number(!match.withoutNeutrals)}"
			request += " +con_logfile matches/log_#{match._id}.txt"

			c = new ssh2()

			c.on 'ready', Meteor.bindEnvironment ->
				c.sftp Meteor.bindEnvironment (error, sftp) ->
					path = "#{Config.get('serverPath')}/dota/matches/#{match._id}.ini"
					console.log path

					sftp.fastPut localPath, path, Meteor.bindEnvironment (error) ->
						if error then throw new Meteor.Error error

						fs.unlinkSync localPath
						console.log request
						c.exec request, Meteor.bindEnvironment (err, stream) ->
							if err then throw new Meteor.Error error

							stream.on 'close', (code, signal) ->
								console.log 'STREAM :: close :: code: ' + code + ', signal: ' + signal

							stream.on 'data', (data) ->
								console.log String data

							stream.stderr.on 'data', (data) ->
								console.log String data

							Matches.update match._id,
								$set:
									server:
										ip: Config.get 'serverIP'
										numberIp: Config.get 'serverIP'
										port: port
										hltvPort: port - 1

							sftp.end()

			c.connect
				host: Config.get 'serverIP'
				port: Config.get 'serverPortSSH'
				username: Config.get 'serverLoginSSH'
				password: Config.get 'serverPasswordSSH'

	parseLogFile: (match, cb) ->
		if match
			c = new ssh2()

			c.on 'ready', Meteor.bindEnvironment ->
				c.sftp Meteor.bindEnvironment (error, sftp) ->
					localPath = "/var/www/dota2comeback.com/assets/log_#{match._id}.txt"

					sftp.fastGet "#{Config.get('serverPath')}/dota/matches/log_#{match._id}.txt", localPath, Meteor.bindEnvironment (error) ->
						fs.readFile localPath, Meteor.bindEnvironment (err, data) ->
							if err
								throw new Meteor.Error err

							parsedData = data.toString().match /\r?\n?    (\w+): (.+)/g
							i = 0

							playersArray = []

							while i < parsedData.length
								data = parsedData[i].match /(\w+): (.+)/

								if data[1] is 'steam_id'
									user = Meteor.users.findOne 'services.steam.id': data[2]

									if user
										heroID = parsedData[i + 1].match(/(\w+): (.+)/)[2]
										kills = parsedData[i + 9].match(/(\w+): (.+)/)[2]
										deaths = parsedData[i + 10].match(/(\w+): (.+)/)[2]
										assists = parsedData[i + 11].match(/(\w+): (.+)/)[2]

										playersArray.push
											userID: user._id
											heroID: heroID
											kills: Number kills
											deaths: Number deaths
											assists: Number assists
								i++

							sftp.end()
							c.end()

							cb playersArray

			c.connect
				host: Config.get 'serverIP'
				port: Config.get 'serverPortSSH'
				username: Config.get 'serverLoginSSH'
				password: Config.get 'serverPasswordSSH'

Meteor.startup -> startLogSocket()