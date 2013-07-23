/*
 * Copyright 2013 by Didgeridoo Unlimited.
 */
package starling.extensions.moyo.effects.example
{
    import flash.geom.Point;

    import starling.animation.IAnimatable;
    import starling.core.Starling;
    import starling.display.DisplayObject;
    import starling.display.Image;
    import starling.display.Sprite;
    import starling.events.Event;
    import starling.events.Touch;
    import starling.events.TouchEvent;
    import starling.events.TouchPhase;
    import starling.extensions.moyo.effects.RenderTextureEffect;
    import starling.text.TextField;
    import starling.textures.Texture;

    /**
     * WaveDistortFilterExample.
     *
     * @author Nils Kübler
     */
    public class RenderTextureEffectExample extends Sprite implements IAnimatable
    {
        [Embed(source="/images/bluepillredpill.png")]
        public static const TestTexture : Class;

        private var tf : TextField;
        private var step : Number = 0.0;
        private var image : Image;

        private var effect : RenderTextureEffect;

        public function RenderTextureEffectExample ()
        {
            addEventListener (Event.ADDED_TO_STAGE, addedToStageHandler);
        }

        private function addedToStageHandler (event : Event) : void
        {
            tf = new TextField (700, 50, "RenderTextureEffect: click somewhere on the image", "Verdana", 12, 0xffffff);
            addChild (tf);

            var texture : Texture = Texture.fromBitmap (new TestTexture ());
            image = new Image (texture);
            image.y = 50;
            image.touchable = true;
            addChild (image);

            try {
                effect = new RenderTextureEffect (256, 256, new <DisplayObject>[image], true, true);
                effect.alpha = 0;
                addChild (effect);
            } catch (e : Error) {
                tf.text = "ERROR:" + e.message;
            }

            this.addEventListener (TouchEvent.TOUCH, touchHandler);
        }

        private function touchHandler (event : TouchEvent) : void
        {
            var touch : Touch = event.getTouch (this);
            if (touch && touch.phase == TouchPhase.BEGAN) {
                step = 0.0;

                var pt : Point = touch.getLocation (this);
                effect.x = pt.x;
                effect.y = pt.y;

                // we need to redraw upon changing the position since we set persistent to true
                effect.forceRedraw ();

                Starling.current.juggler.add (this);
            }
        }

        public function advanceTime (time : Number) : void
        {
            effect.alpha += time;
            if (effect.alpha >= 1.0) {
                effect.alpha = 0;
                Starling.current.juggler.remove (this);
            }
        }

    }
}
