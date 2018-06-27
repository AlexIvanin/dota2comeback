scrollToHash = (hash, time) ->
	time = time || 200;
	if hash is '/' then $('body').animate scrollTop: 0, time
	else if $(hash).length then $('body').animate scrollTop: $(hash).offset().top - 60, time
	else $('body').animate scrollTop: 0, time

Template.help.events
	'click a.anchor': (e, t) -> scrollToHash e.currentTarget.hash

Template.help.rendered = -> $('body').scrollspy target: '.bs-docs-sidebar', offset: 60