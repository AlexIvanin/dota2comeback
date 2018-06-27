Template.noveltyEditModal.rendered = ->
	CKEDITOR.replace 'inputDescription'
	CKEDITOR.replace 'inputText'
	CKEDITOR.instances.inputText.setData @data.text
	CKEDITOR.instances.inputDescription.setData @data.description
	$('#setOneComment').attr 'checked', @data.oneComment

Template.noveltyEditModal.events
	'click .btn-save-novelty': ->
		News.update @_id,
			$set:
				title: $('#inputTitle').val()
				image: $('#inputImage').val()
				text: CKEDITOR.instances.inputText.getData()
				description: CKEDITOR.instances.inputDescription.getData()
				oneComment: $('#setOneComment').prop 'checked'
		, -> $('#noveltyEditModal').modal 'hide'