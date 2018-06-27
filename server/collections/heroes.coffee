@Heroes = new Meteor.Collection 'heroes'
@UserHeroes = new Meteor.Collection 'userHeroes'

Heroes.before.find excludeCounter
UserHeroes.before.find excludeCounter

Meteor.publish 'heroes', ->
	@unblock()
	Heroes.find()

if Meteor.settings and Meteor.settings.heroes
	heroes = Meteor.settings.heroes

	if heroes.length > Heroes.find().count()
		heroes.forEach (hero) ->
			unless Heroes.findOne hero.id
				Heroes.insert
					_id: hero.id
					name: hero.name
					className: hero.className