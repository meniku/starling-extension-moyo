# Starling Extension: Moyo

Collection of Starling Extensions developed primary for the [Moyo-Game][moyo].

Examples are provided [here][example] and are also included in the source code.

## Effects
Effects are a bit like the filters in `Starling`. However they are not bound to a specific `DisplayObject`. Instead,
they are independent DisplayObjects which can be added anywhere in the DisplayList.

Currently there is only one effect contained: the `WaveDistortEffect`. It is a customizable fragment shader effect
which utilizes the `RenderTexture`.

### Using the WaveDistortEffect

Initialization:

```
    var effect:WaveDistortEffect = new WaveDistortEffect (512, 512, new <DisplayObject>[stage]);
    effect.x = 300;
    effect.y = 300;
    addChild (effect);
```

This creates a 512x512 WaveDistortEffect based on the contents of the whole stage. You may chose different DisplayObject
as the source for the effect if you wish to. This way you can prevent that undesired objects such as the HUD are
included in the effect.

The last two Boolean parameters are `centerPivot` and `persistent`:
 - `centerPivot` will set `pivotX` and `pivotY` to the center of the object. This allows the effect to be placed more
    easily.
 - `persistent` will be false in the most cases. If you set this to true, the texture will be rendered only once,
    gaining performance but changes on your source objects will not be rendered.

To actually display the effect as an animation, you have to update the `step` variable from frame to frame:
```
    // do this every frame:
    effect.step += 0.02;
    if(effect.step >= 1.0) {
        // when we reach 1.0, the effect is done and we can remove it
        effect.removeFromParent(true);
    }
```

For further properties for the effect, please take a look at the [examples][example].

## Plans

It's planned to utilize the `Juggler` and provide some kind of Wrapper to simplify the usage of the effects. The goal
is to have a similar API as `Tweens` have.

 [example]: http://labs.nkuebler.de/starling-extension-moyo
 [moyo]: http://moyo-game.com
