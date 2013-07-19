/*
 * Copyright 2013 by Didgeridoo Unlimited.
 */
package starling.extensions.moyo.filters
{
    import flash.display3D.Context3D;
    import flash.display3D.Context3DProgramType;
    import flash.display3D.Program3D;
    import flash.geom.Point;

    import starling.core.RenderSupport;

    import starling.display.DisplayObject;

    import starling.filters.FragmentFilter;
    import starling.filters.FragmentFilterMode;
    import starling.textures.Texture;

    /**
     * WaveDistortFilter.
     *
     * @author Nils Kübler
     */
    public class WaveDistortFilter extends FragmentFilter
    {
        public var centerPoint:Point = new Point(0,0);
        public var strength:Number = 0.0; // 0.0 -> 0.5 -> 0.0
        public var step:Number = 0.0;     // 0.0 -> 1.0

        private static const EFFECT_WIDTH = 500;
        private static const EFFECT_HEIGHT= 500;

        // Converted from https://www.shadertoy.com/view/XdfGz2
        private static const FRAGMENT_SHADER : String =

            // ft1.x = sin((v0.y + t * 0.2) * 100.0) * tn;
            "add ft1.x, v0.y, fc1.x\n" +
            "mul ft1.x, ft1.x, fc1.y\n" +
            "sin ft1.x, ft1.x\n" +
            "mul ft1.x, ft1.x, fc0.z\n" +

            // dist = max(0.0, 0.5 - distance(Center Point, v0) / step ) ^ 2;
            "sub ft2.xy, fc0.xy, v0.xy\n" +
            "abs ft2.xy, ft2.xy\n" +
            "div ft2.xy, ft2.xy, fc0.ww\n" +
            "sub ft2.xy, fc1.zz, ft2.xy\n" +
            "max ft2.xy, fc1.ww, ft2.xy\n" +
            "pow ft2.xy, ft2.xy, fc2.xx\n" +

            // ft1.x = ft1.x * ft2.x * ft2.y
            "mul ft1.x, ft1.x, ft2.x\n" +
            "mul ft1.x, ft1.x, ft2.y\n" +

            // ft0.x = v0.x + ft1.x
            "mov ft0, v0\n" +
            "add ft0.x, ft0.x, ft1.x\n" +

            "tex oc, ft0, fs0 <2d,norepeat,linear>\n";


        private var fc0 : Vector.<Number> = new <Number>[      0,   // Center Point X
                                                               0,   // Center Point Y
                                                               0,   // Strength (0 - 0.5 - 0, interpolated over the animation length)
                                                               0];  // Step     (0 - 1, interpolated over the animation length)

        private var fc1 : Vector.<Number> = new <Number> [     0,     // step * 0.2
                                                               100.0, // const
                                                               0.5,   // const
                                                               0.0];  // const

        private var fc2 : Vector.<Number> = new <Number> [
                                                                2.0, // const
                                                                0,
                                                                0,   // offsetX
                                                                0 ]; // offsetY

        private var mShaderProgram : Program3D;

        private var lastCenterPoint:Point = new Point(-1, -1);

        public function WaveDistortFilter ()
        {
        }

        public override function dispose () : void
        {
            if (mShaderProgram) {
                mShaderProgram.dispose();
            }
            super.dispose();
        }

        protected override function createPrograms () : void
        {
            mShaderProgram = assembleAgal(FRAGMENT_SHADER);
            this.mode = FragmentFilterMode.ABOVE;
        }

        override public function render(object:DisplayObject, support:RenderSupport, parentAlpha:Number):void
        {

            if(lastCenterPoint.x != centerPoint.x || lastCenterPoint.y != centerPoint.y) {
                lastCenterPoint.x = centerPoint.x;
                lastCenterPoint.y = centerPoint.y;
//                marginX = Math.min(0, -(object.width - EFFECT_WIDTH));
//                marginY = Math.min(0, -(object.height - EFFECT_HEIGHT));
//                offsetX = marginX + centerPoint.x - EFFECT_WIDTH / 2;
//                offsetY = marginY + centerPoint.y - EFFECT_HEIGHT / 2;
            }
            super.render(object, support, parentAlpha);
        }

        protected override function activate (pass : int, context : Context3D, texture : Texture) : void
        {

//            fc0[0] = //(0.5 + offsetX / texture.width) ;
//            fc0[1] = //(0.5 + offsetY / texture.height);
            fc0[0] = centerPoint.x / texture.width;
            fc0[1] = centerPoint.y / texture.width;
            fc0[2] = strength;
            fc0[3] = step;

            fc1[0] = step * 0.2;
            fc1[1] = fc1[1];
            fc1[2] = 0.5;
            fc1[3] = 0.0;

            fc2[0] = fc2[0];
            fc2[1] = fc2[1];
//            fc2[2] = offsetX / texture.width;
//            fc2[3] = offsetY / texture.height;

            context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 0, fc0, 1);
            context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 1, fc1, 1);
            context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 2, fc2, 1);

            context.setProgram(mShaderProgram);
        }


    }
}
