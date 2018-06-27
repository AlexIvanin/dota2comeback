Template.news.events
	'click .btn-remove-novelty': -> Meteor.call 'newsRemoveNovelty', @_id