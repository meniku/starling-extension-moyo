/*
 * Copyright 2013 by Didgeridoo Unlimited.
 */
package starling.extensions.moyo.filters
{
    import flash.display3D.Context3D;
    import flash.display3D.Context3DProgramType;
    import flash.display3D.Program3D;

    import starling.filters.FragmentFilter;
    import starling.textures.Texture;

    /**
     * WaveDistortFilter.
     *
     * @author Nils Kübler
     */
    public class SineFilter extends FragmentFilter
    {
        private static const FRAGMENT_SHADER:String =
            "mov ft0, v0\n" +
            "sub ft1.x, v0.y, fc0.z\n" +
            "mul ft1.x, ft1.x, fc0.w\n" +
            "sin ft1.x, ft1.x\n" +
            "mul ft1.x, ft1.x, fc0.y\n" +

            // horizontal
            "mul ft1.y, ft1.x, fc1.x\n" +
            "add ft0.x, ft0.x, ft1.y\n" +

// vertical
            "mul ft1.z, ft1.x, fc1.y\n" +
            "add ft0.y, ft0.y, ft1.z\n" +

            "tex oc, ft0, fs0<2d, wrap, linear, mipnone>";


            private var mVars:Vector.<Number> = new <Number>[1, 1, 1, 1];
        private var mBooleans:Vector.<Number> = new <Number>[1, 1, 1, 1];
        private var mShaderProgram:Program3D;

        private var mAmplitude:Number
        private var mTicker:Number;
        private var mFrequency:Number;
        private var mIsHorizontal:Boolean = true;

        /**
         *
         * @param amplitude wave amplitude
         * @param frequency wave frequency
         * @param ticker position of effect (use to animate)
         */
        public function SineFilter(amplitude:Number=0.0, frequency:Number=0.0, ticker:Number=0.0)
        {
            mAmplitude	= amplitude;
            mTicker	= ticker;
            mFrequency	= frequency;
        }

        public override function dispose():void
        {
            if (mShaderProgram) mShaderProgram.dispose();
            super.dispose();
        }

        protected override function createPrograms():void
        {
            mShaderProgram = assembleAgal(FRAGMENT_SHADER);
        }

        protected override function activate(pass:int, context:Context3D, texture:Texture):void
        {
            mVars[1] = mAmplitude / texture.height;
            mVars[2] = mTicker;
            mVars[3] = mFrequency ;

            mBooleans[0] = int(mIsHorizontal);
            mBooleans[1] = int(!mIsHorizontal);

            context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 0, mVars,	1);
            context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 1, mBooleans,	1);
            context.setProgram(mShaderProgram);
        }

        public function get amplitude():Number { return mAmplitude; }
        public function set amplitude(value:Number):void { mAmplitude = value; }

        public function get ticker():Number { return mTicker; }
        public function set ticker(value:Number):void { mTicker = value; }

        public function get frequency():Number { return mFrequency; }
        public function set frequency(value:Number):void { mFrequency = value; }

        public function get isHorizontal():Boolean { return mIsHorizontal; }
        public function set isHorizontal(value:Boolean):void { mIsHorizontal = value; }
    }
}
