/*
 * Copyright 2013 by Didgeridoo Unlimited.
 */
package starling.extensions.moyo.filters.example
{
    import starling.events.EnterFrameEvent;
    import starling.events.Touch;
    import starling.events.TouchEvent;
    import starling.events.TouchPhase;

    import starling.display.Image;
    import starling.display.Sprite;
    import starling.events.Event;
    import starling.extensions.moyo.filters.WaveDistortFilter;
    import starling.text.TextField;
    import starling.textures.Texture;

    /**
     * WaveDistortFilterExample.
     *
     * @author Nils Kübler
     */
    public class WaveDistortFilterExample extends Sprite
    {
//        [Embed(source="/images/tex.jpg")]
        [Embed(source="/images/bluepillredpill.png")]
        public static const BluePillRedPill:Class;
        private var theFilter : WaveDistortFilter;

        private var tf:TextField;
        private var step:Number = 0.0;
        private var image : Image;

        public function WaveDistortFilterExample ()
        {
            addEventListener(Event.ADDED_TO_STAGE, addedToStageHandler);

            tf = new TextField(700, 50, "WaveDistortFilterExample: click somewhere on the image", "Verdana", 12, 0xffffff);
            addChild(tf);
        }

        private function addedToStageHandler (event : Event) : void
        {
            var texture:Texture = Texture.fromBitmap(new BluePillRedPill());
            image = new Image(texture);
            image.y = 50;
            image.touchable = true;
            try {
                theFilter = new WaveDistortFilter();
                image.filter = theFilter;
                addChild(image);
            } catch(e:Error) {
               tf.text = "ERROR:" + e.message;
            }

            this.addEventListener(TouchEvent.TOUCH, touchHandler);
        }

        private function touchHandler (event : TouchEvent) : void
        {

            var touch:Touch = event.getTouch(this);
            if(touch && touch.phase == TouchPhase.BEGAN) {
                step = 0.0;
                theFilter.centerPoint = touch.getLocation(image);
                trace('set centerPoint at ' + theFilter.centerPoint.x + ', ' + theFilter.centerPoint.y);
                addEventListener(EnterFrameEvent.ENTER_FRAME, enterFrameHandler);
            }
        }

        private function enterFrameHandler (event : Event) : void
        {
            step += 0.05;

            if(step > 1.0) {
                theFilter.step = 0;
                theFilter.strength = 0;
                removeEventListener(Event.ENTER_FRAME, enterFrameHandler);

            } else if(step > 0.5) {
                theFilter.strength = 1.0 - step;
            } else {
                theFilter.strength = step;
            }
            theFilter.step = step;
        }
    }
}
