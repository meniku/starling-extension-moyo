/*
 * Copyright 2013 by Didgeridoo Unlimited.
 */
package starling.extensions
{

    import feathers.controls.TabBar;
    import feathers.data.ListCollection;
    import feathers.themes.AeonDesktopTheme;

    import starling.display.Sprite;
    import starling.events.Event;
    import starling.extensions.moyo.effects.example.RenderTextureEffectExample;
    import starling.extensions.moyo.effects.example.WaveDistortEffectExample;

    /**
     * MoyoFilterExampleSelector.
     *
     * @author Nils Kübler
     */
    public class MoyoExampleSelector extends Sprite
    {
        private var examples : ListCollection;

        private var _currentExample : Sprite = null;
        private var theme : AeonDesktopTheme;
        private var tabBar : TabBar;

        public function MoyoExampleSelector ()
        {
            addEventListener (Event.ADDED_TO_STAGE, addedToStageHandler);
            examples = new ListCollection ([
                                               { "label": "Render Texture Effect", "class": RenderTextureEffectExample },
                                               { "label": "Wave Distort Effect", "class": WaveDistortEffectExample },
                                           ]);
        }

        private function addedToStageHandler (event : Event) : void
        {
            theme = new AeonDesktopTheme (this);
            stage.color = 0x000000;

            tabBar = new TabBar ();
            tabBar.dataProvider = examples;
            tabBar.x = 100;
            tabBar.addEventListener (Event.CHANGE, tabBar_changedHandler);
            addChild (tabBar);
        }

        private function tabBar_changedHandler (event : Event) : void
        {
            currentExample = new (tabBar.selectedItem['class']);
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
