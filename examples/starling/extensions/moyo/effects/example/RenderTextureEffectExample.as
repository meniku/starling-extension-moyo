/*
 * Copyright 2013 by Didgeridoo Unlimited.
 */
package starling.extensions.moyo.effects.example
{
    import flash.geom.Point;

    import starling.display.Image;
    import starling.display.Sprite;
    import starling.events.EnterFrameEvent;
    import starling.events.Event;
    import starling.events.Touch;
    import starling.events.TouchEvent;
    import starling.events.TouchPhase;
    import starling.extensions.moyo.effects.Polygon;
    import starling.extensions.moyo.effects.RenderTextureEffect;
    import starling.extensions.moyo.filters.WaveDistortFilter;
    import starling.text.TextField;
    import starling.textures.Texture;

    /**
     * WaveDistortFilterExample.
     *
     * @author Nils Kübler
     */
    public class RenderTextureEffectExample extends Sprite
    {
//        [Embed(source="/images/tex.jpg")]
        [Embed(source="/images/bluepillredpill.png")]
        public static const BluePillRedPill : Class;

        private var tf : TextField;
        private var step : Number = 0.0;
        private var image : Image;

        private var effect:RenderTextureEffect;

        public function RenderTextureEffectExample ()
        {
            addEventListener (Event.ADDED_TO_STAGE, addedToStageHandler);

            tf = new TextField (700, 50, "PolygonEffectExample: click somewhere on the image", "Verdana", 12, 0xffffff);
            addChild (tf);
        }

        private function addedToStageHandler (event : Event) : void
        {
            var texture : Texture = Texture.fromBitmap (new BluePillRedPill ());
            image = new Image (texture);
            image.y = 50;
            image.touchable = true;
            addChild(image);
            try {
                effect = new RenderTextureEffect(512, 512);
//                effect.pivotX = 50;
//                effect.pivotY = 50;
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
                var pt:Point = touch.getLocation(root);
                effect.x = pt.x;
                effect.y = pt.y;
                addEventListener (EnterFrameEvent.ENTER_FRAME, enterFrameHandler);
            }
        }

        private function enterFrameHandler (event : Event) : void
        {
            step += 0.05;

            effect.alpha = step;

            if (step > 1.0) {
                step = 0;
                effect.alpha = 0;
                removeEventListener (Event.ENTER_FRAME, enterFrameHandler);

            }
        }
    }
}