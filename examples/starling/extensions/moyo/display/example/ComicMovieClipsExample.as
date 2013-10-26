/*
 * Copyright 2013 by Didgeridoo Unlimited.
 */
package starling.extensions.moyo.display.example
{
    import feathers.controls.ButtonGroup;
    import feathers.controls.PickerList;
    import feathers.controls.TabBar;
    import feathers.data.ListCollection;

    import flash.geom.Point;

    import starling.animation.IAnimatable;

    import starling.core.Starling;

    import starling.display.DisplayObject;
    import starling.display.Image;
    import starling.display.MovieClip;
    import starling.display.Quad;
    import starling.display.Sprite;
    import starling.events.Event;
    import starling.events.Touch;
    import starling.events.TouchEvent;
    import starling.events.TouchPhase;
    import starling.extensions.moyo.display.ComicMovieClip;
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
    public class ComicMovieClipsExample extends Sprite
    {
        [Embed(source="/images/moyo_frame1.png")]
        public static const Frame1 : Class;

        [Embed(source="/images/moyo_frame2.png")]
        public static const Frame2 : Class;

        private var tf : TextField;
        private var mc : ComicMovieClip;
        private var background : Quad;

        public function ComicMovieClipsExample ()
        {
            addEventListener (Event.ADDED_TO_STAGE, addedToStageHandler);
        }

        private function addedToStageHandler (event : Event) : void
        {
            tf = new TextField (700, 50, "ComicMovieClipsExample", "Verdana", 12, 0xffffff);
            addChild (tf);

            background = new Quad(512, 512, 0xffffff);
            background.y = 50;
            addChild(background);

            var texture1 : Texture = Texture.fromBitmap (new Frame1 ());
            var texture2 : Texture = Texture.fromBitmap (new Frame2 ());
            mc = new ComicMovieClip(new <Texture>[texture1, texture2]);
            mc.y = 50;
            Starling.juggler.add(mc);
            addChild (mc);

        }
    }
}
