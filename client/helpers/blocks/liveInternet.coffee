Template.liveInternet.getLiveCounter = ->
	s = if typeof(screen) is 'undefined' then '' else ';s'
	color = if screen.colorDepth then screen.colorDepth else screen.pixelDepth

	"#{escape(document.referrer)}#{s}#{screen.width}*#{screen.height}*#{color};u#{escape(document.URL)};#{Math.random()}"