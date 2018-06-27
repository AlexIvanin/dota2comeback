@inArray = (value, array) ->
	i = 0
	while i < array.length
		return true if array[i] is value
		i++
	false

@getAverageOfArray = (array) ->
	sum = 0
	i = 0

	while i < array.length
		sum += Number array[i]
		i++

	sum / array.length