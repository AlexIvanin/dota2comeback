Template.footer.theme = -> ReactiveStore.get 'theme'

Template.footer.events
	'change #changeTheme': (e) -> ReactiveStore.set 'theme', e.currentTarget.value