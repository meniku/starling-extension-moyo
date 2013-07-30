/*
 * Copyright 2013 by Didgeridoo Unlimited.
 */
package starling.extensions.moyo.effects.example
{
    import feathers.controls.ButtonGroup;
    import feathers.controls.PickerList;
    import feathers.controls.TabBar;
    import feathers.data.ListCollection;

    import flash.geom.Point;

    import starling.display.DisplayObject;
    import starling.display.Image;
    import starling.display.Sprite;
    import starling.events.Event;
    import starling.events.Touch;
    import starling.events.TouchEvent;
    import starling.events.TouchPhase;
    import starling.extensions.moyo.effects.RenderTextureEffect;
    import starling.filters.BlurFilter;
    import starling.filters.ColorMatrixFilter;
    import starling.text.TextField;
    import starling.textures.Texture;
    import starling.utils.Color;

    /**
     * WaveDistortFilterExample.
     *
     * @author Nils Kübler
     */
    public class RenderTextureEffectExample extends Sprite
    {
        [Embed(source="/images/bluepillredpill.png")]
        public static const TestTexture : Class;

        private var tf : TextField;
        private var image : Image;
        private var list : TabBar = new TabBar ();

        private var effect : RenderTextureEffect;

        public function RenderTextureEffectExample ()
        {
            addEventListener (Event.ADDED_TO_STAGE, addedToStageHandler);
        }

        private function addedToStageHandler (event : Event) : void
        {
            tf = new TextField (700, 50, "RenderTextureEffect: click somewhere on the image and drag around", "Verdana", 12, 0xffffff);
            addChild (tf);

            var texture : Texture = Texture.fromBitmap (new TestTexture ());
            image = new Image (texture);
            image.y = 50;
            image.touchable = true;
            addChild (image);

            try {
                effect = new RenderTextureEffect (256, 256, new <DisplayObject>[image], true, true);
                effect.alpha = 0.0;
                addChild (effect);
            } catch (e : Error) {
                tf.text = "ERROR:" + e.message;
            }

            addControls ();
            this.addEventListener (TouchEvent.TOUCH, touchHandler);
        }

        private function touchHandler (event : TouchEvent) : void
        {
            var touch : Touch = event.getTouch (this);
            if (touch) {
                var pt : Point = touch.getLocation (this);
                effect.x = pt.x;
                effect.y = pt.y;

                if (touch.phase == TouchPhase.BEGAN) {
                    effect.alpha = 1.0;
                    // we need to redraw upon changing the position since we set persistent to true
                    effect.forceRedraw (true);
                } else if (touch.phase == TouchPhase.ENDED) {
                    effect.alpha = 0.0;
                }
            }
        }

        private function addControls () : void
        {
            var blurFilter:BlurFilter = new BlurFilter (4, 4, 1);

            var colorMatrixFilter:ColorMatrixFilter = new ColorMatrixFilter();
            colorMatrixFilter.adjustBrightness(0.5);
            colorMatrixFilter.adjustSaturation(0.5);


            var data : ListCollection = new ListCollection ([
                                                                { "label": "None", "instance": null },
                                                                { "label": "Blur", "instance": blurFilter },
                                                                { "label": "Color", "instance": colorMatrixFilter }
                                                            ]);
            list.dataProvider = data;
            list.x = 710;
            list.y = 100;
            list.selectedIndex = 0;
            list.direction =  ButtonGroup.DIRECTION_VERTICAL;
            list.addEventListener (Event.CHANGE, list_changedHandler);
            addChild (list);
        }

        private function list_changedHandler (event : Event) : void
        {
            effect.filter = list.selectedItem['instance'];
        }
    }
}
