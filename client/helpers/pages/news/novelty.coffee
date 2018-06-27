$.fn.setCursorPosition = (pos) ->
	@each (index, elem) ->
		if elem.setSelectionRange
			elem.setSelectionRange pos, pos
		else if elem.createTextRange
			range = elem.createTextRange()
			range.collapse on
			range.moveEnd 'character', pos
			range.moveStart 'character', pos
			range.select()
	@

Template.novelty.events
	'click .btn-remove-novelty': -> Meteor.call 'newsRemoveNovelty', @_id

	'click .btn-send-novelty-comment': ->
		message = $('#comment').val()
		if message
			Meteor.call 'newsAddComment', @_id, message, (e, r) ->
				if e then alert e
				else $('#comment').val ''
		else
			alert 'Введите текст комментария'

	'keypress #comment': (e) ->
		if e.which is 13
			message = $('#comment').val()
			if message
				Meteor.call 'newsAddComment', @_id, message, (e, r) ->
					if e then alert e
					else $('#comment').val ''
			else
				alert 'Введите текст комментария'

	'click .btn-remove-comment': -> Meteor.call 'newsRemoveComment', @_id

	'click .btn-reply-comment': ->
		textarea = $ '#comment'

		textarea.val "#{@author().profile.name}, "
		textarea.focus()
		textarea.setCursorPosition textarea.val().length