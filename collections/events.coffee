Events.helpers
	paymentGetMobileOperator: ->
		if @isPayment
			switch @params.operator
				when 'mf' then 'Мегафон'
				when 'mts' then 'МТС'
				when 'beeline' then 'Билайн'

	paymentGetType: ->
		if @isPayment
			switch @params.paymentType
				when 'mc' then 'Мобильный платеж'
				when 'sms' then 'SMS-оплата'
				when 'card' then 'Пластиковая карта'
				when 'webmoney' then 'WebMoney'
				when 'yandex' then 'Яндекс.Деньги'
				when 'qiwi' then 'Qiwi'
				when 'paypal' then 'PayPal'
				when 'liqpay' then 'LiqPay'
				when 'alfaClick' then 'Альфа-Клик'
				when 'cash' then 'Наличные'