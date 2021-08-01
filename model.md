# Entity options
```lua
exports.qtarget:AddTargetModel(entity, parameters)
```
##### Registers the defined options to display on all entities with the provided model hash.

```lua
AddEventHandler('eventname', function(data)
	print(data.label, data.num, data.entity)
end

exports.qtarget:AddTargetModel({
	options = {
		{
			event = "eventname",
			icon = "fas fa-box-circle-check",
			label = "action 1",
			num = 1
		},
		{
			event = "eventname",
			icon = "fas fa-box-circle-check",
			label = "action 2"
			num = 2
		},
	},
	distance = 2
})
```

##### Options can be removed by calling the remove export, with all labels as entries in an array.
```lua
exports.qtarget:RemoveTargetModel({
	'action 1', 'action 2'
})
```