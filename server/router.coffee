Router.onBeforeAction Iron.Router.bodyParser.urlencoded 'extended': no

Router.map ->
	@route 'unitpay',
		where: 'server'
		controller: 'UnitPayController'