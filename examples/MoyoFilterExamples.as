/*
 * Copyright 2013 by Didgeridoo Unlimited.
 */
package
{
    import flash.display.Sprite;
    import flash.events.Event;

    import starling.core.Starling;
    import starling.extensions.moyo.filters.example.MoyoFilterExampleSelector;

    /**
     * MoyoFilterExamples.
     *
     * @author Nils Kübler
     */
    [SWF(width=900, height=750, backgroundColor=0x000000, frameRate=60)]
    public class MoyoFilterExamples extends Sprite
    {
        private var starling : Starling;

        public function MoyoFilterExamples ()
        {
            addEventListener(Event.ADDED_TO_STAGE, addedToStageHandler);
        }

        private function addedToStageHandler (event : Event) : void
        {
            this.starling = new Starling( MoyoFilterExampleSelector, stage);
            this.starling.enableErrorChecking = true;
            this.starling.showStats = true;
            this.starling.start( );
        }
    }
}
