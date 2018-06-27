@News = new Meteor.Collection 'news'
@newsComments = new Meteor.Collection 'newsComments'

News.before.find excludeCounter
newsComments.before.find excludeCounter

Meteor.publish 'news', (limit) ->
	@unblock()
	News.find {},
		sort:
			date: -1
		fields:
			title: 1
			image: 1
			description: 1
			date: 1

Meteor.publish 'novelty', (id) ->
	@unblock()
	novelty = News.findOne id

	if novelty
		News.update id, $inc: viewsCount: 1

		noveltyCursor = News.find id,
			fields:
				userId: 0
				description: 0
				image: 0
	else
		@ready()

Meteor.publish 'noveltyComments', (id) ->
	@unblock()
	novelty = News.findOne id

	if novelty
		self = @

		handle = newsComments.find(noveltyId: id).observeChanges 
			added: (id, fields) ->
				user = Meteor.users.findOne fields.userId, fields: 'services.resume': 0

				self.added 'newsComments', id, fields
				if user
					self.added 'users', user._id, user

			changed: (id, fields) -> self.changed 'newsComments', id, fields
			removed: (id) -> self.removed 'newsComments', id

		@onStop -> handle.stop()
		@ready()
	else
		@ready()

News.allow
	insert: (userId) -> Roles.userIsInRole userId, 'admin'
	update: (userId) -> Roles.userIsInRole userId, 'admin'
	remove: (userId) -> Roles.userIsInRole userId, 'admin'

newsComments.allow
	insert: (userId) -> Roles.userIsInRole userId, 'admin'
	update: (userId) -> Roles.userIsInRole userId, 'admin'
	remove: (userId) -> Roles.userIsInRole userId, 'admin'

Meteor.methods
	newsAddNovelty: (novelty) ->
		@unblock()

		if @userId and Roles.userIsInRole(@userId, 'admin')
			News.insert
				_id: String incrementCounter News
				date: Date.now()
				userId: @userId
				description: novelty.description
				text: novelty.text
				image: novelty.image
				title: novelty.title
				oneComment: novelty.oneComment
				viewsCount: 0
				commentsCount: 0

	newsRemoveNovelty: (id) ->
		@unblock()

		if @userId and Roles.userIsInRole(@userId, 'admin')
			News.remove id
			newsComments.remove noveltyId: id

	newsAddComment: (noveltyId, message) ->
		@unblock()

		if @userId and noveltyId and message
			check noveltyId, String
			check message, String

			novelty = News.findOne noveltyId

			throw new Meteor.Error('Такой новости не существует') unless novelty
			throw new Meteor.Error('Слишком короткий комментарий') if message.length < 1

			if novelty.oneComment and newsComments.findOne(noveltyId: noveltyId, userId: @userId)
				throw new Meteor.Error 'К этой новости разрешено оставлять не более одного комментария'

			News.update noveltyId, $inc: commentsCount: 1

			newsComments.insert
				_id: String incrementCounter newsComments
				date: Date.now()
				noveltyId: noveltyId
				userId: @userId
				message: message

	newsRemoveComment: (commentId) ->
		@unblock()

		if @userId and Roles.userIsInRole @userId, 'admin'
			comment = newsComments.findOne commentId
			News.update comment.noveltyId, $inc: commentsCount: -1
			newsComments.remove commentId