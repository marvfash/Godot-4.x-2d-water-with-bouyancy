# Godot 4.x 2D water with buoyancy
This is a working 4.0 fork of the work of Thiago Bruno [here](https://github.com/thrbr84/godot_buoyancyWaterObject). Go support him by buying him a [cup of coffee](https://www.buymeacoffee.com/thiagobruno).

I have also translated the variables into English.

### How to use the water:
- Install the Polygon2Dwater addon in your project, enable it in the settings, and use the "Polygon2Dwater" node to simulate and configure your water.

### How to simulate the buoyancy effect:
- Check the scripts for the boat and the ball in the examples.

### For your RigidBody2D:
- When your object comes into contact with the water, the water tries to call these two functions on your RigidBody2D.

```python
func _on_water_entered(_agua, _altura, _tensao, _amortecimento):
    # Implement your script
```

```python
func _on_water_exited():
    # Implement your script
```


[![Watch on Youtube](https://img.youtube.com/vi/2SPWcQss4Ls/0.jpg)](https://www.youtube.com/watch?v=2SPWcQss4Ls)
