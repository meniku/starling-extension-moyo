/*
 * Copyright 2013 by Didgeridoo Unlimited.
 */
package starling.extensions.moyo.effects.example
{
    import feathers.controls.Label;
    import feathers.controls.Slider;
    import feathers.controls.TextArea;

    import flash.geom.Point;
    import flash.text.TextFormat;
    import flash.utils.Dictionary;

    import starling.animation.IAnimatable;
    import starling.core.Starling;
    import starling.display.DisplayObject;
    import starling.display.Image;
    import starling.display.Sprite;
    import starling.events.Event;
    import starling.events.Touch;
    import starling.events.TouchEvent;
    import starling.events.TouchPhase;
    import starling.extensions.moyo.effects.WaveDistortEffect;
    import starling.text.TextField;
    import starling.textures.Texture;

    /**
     * WaveDistortFilterExample.
     *
     * @author Nils Kübler
     */
    public class WaveDistortEffectExample extends Sprite implements IAnimatable
    {
        [Embed(source="/images/tex.jpg")]
        public static const TestTexture : Class;

        private var tf : TextField;
        private var image : Image;
        private var textArea : TextArea;
        private var changedProperties : Dictionary = new Dictionary ();

        private var effect : WaveDistortEffect;

        public function WaveDistortEffectExample ()
        {
            addEventListener (Event.ADDED_TO_STAGE, addedToStageHandler);
        }

        private function addedToStageHandler (event : Event) : void
        {
            tf = new TextField (700, 50, "WaveDistortEffect: click somewhere on the image", "Verdana", 12, 0xffffff);
            addChild (tf);

            image = new Image (Texture.fromBitmap (new TestTexture ()));
            image.y = 50;
            image.touchable = true;
            addChild (image);

            try {
                effect = new WaveDistortEffect (512, 512, new <DisplayObject>[image], true);
                addChild (effect);
            } catch (e : Error) {
                tf.text = "ERROR:" + e.message;
            }

            image.addEventListener (TouchEvent.TOUCH, touchHandler);

            addControls ();
        }

        private function touchHandler (event : TouchEvent) : void
        {
            var touch : Touch = event.getTouch (this);
            if (touch && touch.phase == TouchPhase.BEGAN) {
                var pt : Point = touch.getLocation (this);
                effect.step = 0.0;
                effect.x = pt.x;
                effect.y = pt.y;
                Starling.current.juggler.add (this);
            }
        }

        public function advanceTime (time : Number) : void
        {
            effect.step += time;
            if (effect.step > 1.0) {
                effect.step = 0;
                Starling.current.juggler.remove (this);
            }
        }

        private function addControls () : void
        {
            var num : uint = 0;

            addSlider ("rotation", -Math.PI, Math.PI, 0.1, num++);
            addSlider ("xInputFactor", -5.0, 5.0, 0.1, num++);
            addSlider ("yInputFactor", -5.0, 5.0, 0.1, num++);
            addSlider ("xOutputFactor", -5.0, 5.0, 0.1, num++);
            addSlider ("yOutputFactor", -5.0, 5.0, 0.1, num++);
            addSlider ("vibration", -1.0, 1.0, 0.1, num++);
            addSlider ("multiplier", -1000, 1000.0, 10, num++);
            addSlider ("strengthFactor", -5.0, 5.0, 0.1, num++);
            addSlider ("extrusion", 0.1, 2.0, 0.1, num++);
            addSlider ("zero", -1.0, 1.0, 0.1, num++);
            addSlider ("centerX", 0, 1.0, 0.1, num++);
            addSlider ("centerY", 0, 1.0, 0.1, num++);

            textArea = new TextArea ();
            textArea.x = 710;
            textArea.y = 50 + 30 * num;
            textArea.width = 180;
            textArea.height = 150;
            addChild (textArea);
        }

        private function addSlider (property : String, min : Number, max : Number, step : Number, i : uint) : void
        {
            var def : Number = this.effect[property];
            var label : Label = new Label ();
            label.text = property + ": " + def;
            label.x = 710;
            label.y = 30 + 30 * i;
            addChild (label);
            label.textRendererProperties.textFormat = new TextFormat ("Verdana", 10, 0xffffff);

            var slider : Slider = new Slider ();
            slider.minimum = min;
            slider.maximum = max;
            slider.step = step;
            slider.x = 710;
            slider.width = 180;
            slider.y = label.y + 15;
            slider.value = this.effect[property];
            slider.addEventListener (Event.CHANGE, function (evt : Event) : void
            {
                effect[property] = slider.value;
                changedProperties[property] = slider.value;
                label.text = property + " : " + slider.value + " / default : " + def;
                updateTextArea ();
            });
            addChild (slider);
        }

        private function updateTextArea () : void
        {
            var text : Array = [];
            for (var key : String in changedProperties) {
                text.push ("effect." + key + " = " + changedProperties[key] + ";");
            }
            textArea.text = text.join ("\n");
        }
    }
}
