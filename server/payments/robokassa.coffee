Meteor.methods
	getRobokassaLink: (sum) ->
		if @userId and sum
			if Config.get('robokassaOn') and Config.get('robokassaLogin')? and Config.get('robokassaKey1')? and Config.get('robokassaKey2')?
				id = incrementCounter Events

				Events.insert
					_id: String id
					isRobokassa: on
					status: 'prepay'
					userId: @userId
					date: Date.now()
					sum: Number sum

				paramsString = "#{Config.get('robokassaLogin')}:#{sum}:#{id}:#{Config.get('robokassaKey1')}"
				hash = crypto.createHash('md5').update(paramsString).digest('hex').toUpperCase()

				link = "https://auth.robokassa.ru/Merchant/Index.aspx"
				link += "?MrchLogin=#{Config.get('robokassaLogin')}"
				link += "&OutSum=#{sum}"
				link += "&InvId=#{id}"
				link += "&Desc=Пополнение+баланса"
				link += "&SignatureValue=#{hash}"

				return link

md5sign = (params, secretKey) ->
	paramsString = "#{params.out_summ}:#{params.inv_id}:#{secretKey}"

	return params.SignatureValue is crypto.createHash('md5').update(paramsString).digest('hex').toUpperCase()

Router.route '/robokassa', ->
	if Config.get('robokassaOn') and Config.get('robokassaLogin')? and Config.get('robokassaKey1')? and Config.get('robokassaKey2')?
		request = @request.query

		unless md5sign(request, Config.get('robokassaKey2'))
			return @response.end 'Invalid HASH'

		payment = Events.findOne _id: request.inv_id

		unless payment
			return @response.end 'Payment not found'

		unless payment.sum is Number(request.out_summ)
			return @response.end 'Not valid sum'

		Meteor.users.update payment.userId, $inc: 'profile.money': Number request.out_summ

		delete request.SignatureValue
		delete request.crc

		Events.update payment._id,
			$set:
				isPayment: on
				status: 'pay'
				params: request
				date: Date.now()

		@response.end "OK#{payment._id}"
,
	where: 'server'