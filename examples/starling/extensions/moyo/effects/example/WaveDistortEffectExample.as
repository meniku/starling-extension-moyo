/*
 * Copyright 2013 by Didgeridoo Unlimited.
 */
package starling.extensions.moyo.effects.example
{
    import feathers.controls.Label;
    import feathers.controls.Slider;
    import feathers.themes.AeonDesktopTheme;

    import flash.geom.Point;
    import flash.text.TextFormat;

    import starling.display.DisplayObject;

    import starling.display.Image;
    import starling.display.Sprite;
    import starling.events.EnterFrameEvent;
    import starling.events.Event;
    import starling.events.Touch;
    import starling.events.TouchEvent;
    import starling.events.TouchPhase;
    import starling.extensions.old.Polygon;
    import starling.extensions.moyo.effects.RenderTextureEffect;
    import starling.extensions.moyo.effects.WaveDistortEffect;
    import starling.extensions.old.WaveDistortFilter;
    import starling.text.TextField;
    import starling.textures.Texture;

    /**
     * WaveDistortFilterExample.
     *
     * @author Nils Kübler
     */
    public class WaveDistortEffectExample extends Sprite
    {
        [Embed(source="/images/tex.jpg")]
        public static const TestTexture : Class;

        private var tf : TextField;
        private var step : Number = 0.0;
        private var image : Image;

        private var effect:WaveDistortEffect;

        public function WaveDistortEffectExample ()
        {
            addEventListener (Event.ADDED_TO_STAGE, addedToStageHandler);

            tf = new TextField (700, 50, "WaveDistortEffect: click somewhere on the image", "Verdana", 12, 0xffffff);
            addChild (tf);
        }

        private function addedToStageHandler (event : Event) : void
        {
            var texture : Texture = Texture.fromBitmap (new TestTexture ());
            image = new Image (texture);
            image.y = 50;
            image.touchable = true;
            addChild(image);
            try {
                effect = new WaveDistortEffect(512, 512, new <DisplayObject>[image]);
                effect.alpha = 0.5;
                effect.pivotX = 256;
                effect.pivotY = 256;
                addChild (effect);
            } catch (e : Error) {
                tf.text = "ERROR:" + e.message;
            }


            var num:uint = 0;
            addSlider("rotation", -Math.PI , Math.PI , 0.1, num++);
            addSlider("vibration", -1.0, 1.0, 0.1, num++);
            addSlider("multiplier", -1000, 1000.0, 10, num++);
            addSlider("extrusion", 0.1, 2.0, 0.1, num++);
            addSlider("zero", -1.0, 1.0, 0.1, num++);
            addSlider("xInputFactor", -5.0, 5.0, 0.1, num++);
            addSlider("yInputFactor", -5.0, 5.0, 0.1, num++);
            addSlider("xOutputFactor", -5.0, 5.0, 0.1, num++);
            addSlider("yOutputFactor", -5.0, 5.0, 0.1, num++);
            addSlider("strengthFactor", -5.0, 5.0, 0.1, num++);
            addSlider("centerX", 0, 1.0, 0.1, num++);
            addSlider("centerY", 0, 1.0, 0.1, num++);

            image.addEventListener (TouchEvent.TOUCH, touchHandler);
        }

        private function touchHandler (event : TouchEvent) : void
        {
            var touch : Touch = event.getTouch (this);
            if (touch && touch.phase == TouchPhase.BEGAN) {
                step = 0.0;
                var pt:Point = touch.getLocation(this);
                effect.x = pt.x;
                effect.y = pt.y;
                effect.forceRedraw();

                trace(pt.y, pt.y);
                addEventListener (EnterFrameEvent.ENTER_FRAME, enterFrameHandler);
            }
        }

        private function enterFrameHandler (event : Event) : void
        {
            effect.step = step += 0.02;

            if (step > 1.0) {
                step = 0;
                removeEventListener (Event.ENTER_FRAME, enterFrameHandler);
            }
        }

        private function addSlider ( property:String, min : Number, max : Number, step : Number, i:uint) : void
        {
            var def:Number = this.effect[property];
            var label:Label = new Label();
            label.text = property + ": " + def;
            label.x = 710;
            label.y = 30 + 30 * i;
            addChild(label);
            label.textRendererProperties.textFormat.color = 0xffffff;// = new TextFormat( "Source Sans Pro", 16, 0x333333 );

            var slider:Slider = new Slider();
            slider.minimum = min;
            slider.maximum = max;
            slider.step = step;
            slider.x = 710;
            slider.width = 180;
            slider.y = label.y + 15;
            slider.value = this.effect[property];
            slider.addEventListener(Event.CHANGE, function(evt:Event) {
                effect[property] = slider.value;
                label.text = property + " : " + slider.value + " / default : " + def;
            } );
            addChild(slider);
        }
    }
}
