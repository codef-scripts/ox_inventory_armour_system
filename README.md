# ox_inventory_armour_system

## Installation

### For ox_inventory

Add the following to `ox_inventory/data/items.lua`:

```lua
['armor_plate'] = {
    label = 'Armor Plate',
    weight = 1000,
    stack = true,
    description = 'Armor plate for the Vest',
    client = {
        image = "armor_plate.png",
    }
},

['armor_vest'] = {
    label = 'Armor Vest',
    weight = 1000,
    stack = true,
    description = 'A Vest To Apply Plates',
    client = {
        image = "armor_vest.png",
    }
},

## Armouring Animation 2
anim = {
                dict = 'clothingtie',
                clip = 'try_tie_positive_a'
            }
```

Then copy the images from the `images` folder to:
- `ox_inventory/web/images`
