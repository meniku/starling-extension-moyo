/*
 * Copyright 2013 by Didgeridoo Unlimited.
 */
package
{
    import flash.display.Sprite;
    import flash.events.Event;

    import starling.core.Starling;
    import starling.extensions.MoyoExampleSelector;

    /**
     * MoyoFilterExamples.
     *
     * @author Nils Kübler
     */
    [SWF(width=900, height=750, backgroundColor=0x000000, frameRate=60)]
    public class MoyoExamplesMain extends Sprite
    {
        private var starling : Starling;

        public function MoyoExamplesMain ()
        {
            addEventListener(Event.ADDED_TO_STAGE, addedToStageHandler);
        }

        private function addedToStageHandler (event : Event) : void
        {
            this.starling = new Starling( MoyoExampleSelector, stage);
            this.starling.enableErrorChecking = true;
            this.starling.showStats = true;
            this.starling.start( );
        }
    }
}
