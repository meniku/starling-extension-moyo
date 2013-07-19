/*
 * Copyright 2013 by Didgeridoo Unlimited.
 */
package starling.extensions.moyo.filters.example
{
    import starling.display.Button;
    import starling.display.Sprite;
    import starling.events.Event;
    import starling.events.Touch;
    import starling.events.TouchEvent;
    import starling.events.TouchPhase;
    import starling.text.TextField;

    /**
     * MoyoFilterExampleSelector.
     *
     * @author Nils Kübler
     */
    public class MoyoFilterExampleSelector  extends Sprite
    {
        private var examples:Object = {
            "WaveDistort" : WaveDistortFilterExample
        };
        private var _currentExample : Sprite = null;

        public function MoyoFilterExampleSelector ()
        {
            addEventListener(Event.ADDED_TO_STAGE, addedToStageHandler);
        }

        private function addedToStageHandler (event : Event) : void
        {
            stage.color = 0x000000;

            var curX:uint = 50;
            for(var name:String in examples) {
                var btn1:TextField = new TextField(100, 20, name, "Verdana", 12, 0xaaaaff);
                btn1.addEventListener(TouchEvent.TOUCH, function(evt:TouchEvent) : void {
                    var touch:Touch = evt.getTouch(btn1);
                    if(touch && touch.phase == TouchPhase.BEGAN) {
                        currentExample = new examples[name];
                    }
                });
                addChild(btn1);
                btn1.x = curX;
                curX += 100;
                if(!currentExample) { currentExample = new examples[name]; }
            }

        }

        private function set currentExample(sprite:Sprite) : void {
            if(this._currentExample) {
                removeChild(_currentExample, true);
            }
            _currentExample = sprite;
            if(_currentExample) {
                _currentExample.y = 20;
                addChild(_currentExample);
            }
        }

        private function get currentExample() : Sprite {
            return _currentExample;
        }
    }
}
