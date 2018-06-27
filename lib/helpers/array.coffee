@inArray = (value, array) ->
	i = 0
	while i < array.length
		return true if array[i] is value
		i++
	false

@averageOfArray = (arr) ->
	x = undefined
	correctFactor = 0
	sum = 0
	x = 0
	while x < arr.length
		arr[x] = +arr[x]
		unless isNaN(arr[x])
			sum += arr[x]
		else
			correctFactor++
		x++
	sum / (arr.length - correctFactor)