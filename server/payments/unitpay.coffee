@UnitPayController = RouteController.extend
	action: ->
		if Config.get('unitpayOn') and Config.get('unitpayKey')?
			@response.setHeader 'Content-Type', 'application/json; charset=utf-8'

			if Config.get('unitpayOn') and Config.get('unitpayKey')?
				method = @params.query.method
				params = {}

				for i of @params.query
					indexExp = i.match /params\[(.*)\]/
					if indexExp
						if indexExp[1] is 'date'
							params[indexExp[1]] = @params.query[i].replace '+', ' '
						else
							params[indexExp[1]] = @params.query[i]

				signKey = params.sign
				delete params.sign

				if md5sign(params, Config.get('unitpayKey')) is signKey
					user = Meteor.users.findOne id: Number params.account

					res =
						unless user
							responseError "Пользователя с ID: #{params.account} не существует"
						else
							switch method
								when 'check'
									responseSuccess 'Успех'

								when 'pay'
									Events.insert
										isPayment: on
										isUnitpay: on
										status: 'pay'
										params: params
										userId: user._id
										date: Date.now()

									Meteor.users.update user._id, $inc: 'profile.money': Number params.profit

									totalUserMoney = user.profile.money + Number params.profit

									responseSuccess "Успешно! #{user.profile.name}, ваш баланс пополнен на #{params.profit} руб. На вашем счету: #{totalUserMoney} руб."

								when 'error'
									Events.insert
										isPayment: on
										isUnitpay: on
										status: 'error'
										params: params
										date: Date.now()

									responseSuccess 'Успех'

								else
									responseSuccess 'Некорректный метод, поддерживаются методы: error, check и pay'

				else
					res = responseError 'Некорректная цифровая подпись'

				@response.end res
			else
				@response.end 'Route isn`t configurated'

md5sign = (params, secretKey) ->
	paramsString = ''
	_.forEach params, (value, index) -> paramsString += value
	paramsString += secretKey
	crypto.createHash('md5').update(paramsString).digest('hex')

responseSuccess = (message) ->
	JSON.stringify
		jsonrpc: '2.0'
		result:
			message: message
		id: 1

responseError = (message) ->
	JSON.stringify
		jsonrpc: '2.0'
		error:
			code: -32000
			message: message
		id: 1