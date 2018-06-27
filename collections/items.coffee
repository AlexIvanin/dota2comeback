Items.helpers
	description: -> Descriptions.findOne @descriptionID

Descriptions.helpers
	name_color: ->
		switch @shortType
			when 'Any' then 'dfdfdf'
			when 'Arcana' then 'ade55c'
			when 'Common' then 'b0c3d9'
			when 'Legendary' then 'd32ce6'
			when 'Mythical' then '8847ff'
			when 'Immortal' then 'e4ae39'
			when 'Rare' then '4b69ff'
			when 'Uncommon' then '5e98d9'