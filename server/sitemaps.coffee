sitemaps.add '/sitemap.xml', ->
	out = [
		page: '/'
		changefreq: 'always'
	,
		page: '/news'
		changefreq: 'daily'
	,
		page: '/top'
		changefreq: 'always'
	,
		page: '/about'
		changefreq: 'monthly'
	,
		page: '/help'
		changefreq: 'monthly'
	,
		page: '/contacts'
		changefreq: 'monthly'
	,
		page: '/donate'
		changefreq: 'monthly'
	]

	users = Meteor.users.find {}, fields: id: 1
	news = News.find {}, fields: _id: 1

	users.forEach (user) ->
		out.push
			page: "/user/#{user.id}"
			changefreq: 'hourly'

	news.forEach (novelty) ->
		out.push
			page: "/news/#{novelty._id}"
			changefreq: 'daily'

	out