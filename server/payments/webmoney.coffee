Router.route '/webmoney', ->
	if Config.get('webmoneyOn') and Config.get('webmoneyKey')
		params = @request.body

		if params
			unless params.LMI_PAYEE_PURSE is Config.get('webmoneyPurse')
				return @response.end('Not valid LMI_PAYEE_PURSE')

			if params.LMI_PREREQUEST is '1'
				if Meteor.users.findOne(id: Number params.LMI_PAYMENT_NO)
					return @response.end 'YES'
				else
					return @response.end('User not found')

			else
				unless checkWebmoneyHash(params, Config.get('webmoneyKey'))
					return @response.end 'Invalid HASH'

				user = Meteor.users.findOne id: Number params.LMI_PAYMENT_NO

				unless user
					return @response.end 'User not found'

				Meteor.users.update user._id, $inc: 'profile.money': Number params.LMI_PAYMENT_AMOUNT

				Events.insert
					isPayment: on
					isWebmoney: on
					status: 'pay'
					params: params
					userId: user._id
					date: Date.now()

				@response.end 'YES'
,
	where: 'server'

checkWebmoneyHash = (params, secretKey) ->
	paramsString = ''

	paramsString += params.LMI_PAYEE_PURSE
	paramsString += params.LMI_PAYMENT_AMOUNT
	paramsString += params.LMI_PAYMENT_NO
	paramsString += params.LMI_MODE
	paramsString += params.LMI_SYS_INVS_NO
	paramsString += params.LMI_SYS_TRANS_NO
	paramsString += params.LMI_SYS_TRANS_DATE
	paramsString += secretKey
	paramsString += params.LMI_PAYER_PURSE
	paramsString += params.LMI_PAYER_WM

	hash = crypto.createHash('sha256').update(paramsString).digest('hex').toUpperCase()

	hash is params.LMI_HASH