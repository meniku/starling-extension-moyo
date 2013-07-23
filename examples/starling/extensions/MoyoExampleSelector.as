/*
 * Copyright 2013 by Didgeridoo Unlimited.
 */
package starling.extensions
{

    import starling.display.DisplayObject;
    import starling.display.Sprite;
    import starling.events.Event;
    import starling.events.Touch;
    import starling.events.TouchEvent;
    import starling.events.TouchPhase;
    import starling.extensions.moyo.effects.example.RenderTextureEffectExample;
    import starling.extensions.moyo.effects.example.WaveDistortEffectExample;
    import starling.text.TextField;

    /**
     * MoyoFilterExampleSelector.
     *
     * @author Nils Kübler
     */
    public class MoyoExampleSelector extends Sprite
    {
        private var examples : Object = {
            "Render Texture Effect": RenderTextureEffectExample,
            "Wave Distort Effect"  : WaveDistortEffectExample
        };

        private var _currentExample : Sprite = null;

        public function MoyoExampleSelector ()
        {
            addEventListener (Event.ADDED_TO_STAGE, addedToStageHandler);
        }

        private function addedToStageHandler (event : Event) : void
        {
            stage.color = 0x000000;

            var curX : uint = 50;
            for (var name : String in examples) {
                var btn1 : TextField = new TextField (150, 20, name, "Verdana", 12, 0xaaaaff);
                btn1.addEventListener (TouchEvent.TOUCH, btn_clickedHandler);
                addChild (btn1);
                btn1.x = curX;
                btn1.name = name;
                curX += 150;
                if (!currentExample) { currentExample = new examples[name]; }
            }
        }

        private function btn_clickedHandler (event : TouchEvent) : void
        {
            var touch : Touch = event.getTouch (DisplayObject (event.currentTarget));
            if (touch && touch.phase == TouchPhase.BEGAN) {
                currentExample = new examples[DisplayObject (event.currentTarget).name];
            }
        }

        private function set currentExample (sprite : Sprite) : void
        {
            if (this._currentExample) {
                removeChild (_currentExample, true);
            }
            _currentExample = sprite;
            if (_currentExample) {
                _currentExample.y = 20;
                addChildAt (_currentExample, 0);
            }
        }

        private function get currentExample () : Sprite
        {
            return _currentExample;
        }
    }
}
