/*
 * Copyright 2013 by Didgeridoo Unlimited.
 */
package starling.extensions.moyo.effects
{
    import flash.display3D.Context3D;
    import flash.display3D.Context3DProgramType;

    import starling.display.DisplayObject;

    /**
     * WaveDistortEffect.
     *
     * @author Nils Kübler
     */
    public class WaveDistortEffect extends RenderTextureEffect
    {
//        public var strength:Number = 0.0;               // 0.0 -> 0.5 -> 0.0
        public var step:Number = 0.0;                   // 0.0 -> 1.0

        private var fc0 : Vector.<Number> = new <Number>[      0,   // Center Point X ( 0 - 1.0 )
                                                               0,   // Center Point Y ( 0 - 1.0 )
                                                               0,   // Strength (0 - 0.5 - 0, interpolated over the animation length)
                                                               0];  // Step     (0 - 1, interpolated over the animation length)

        private var fc1 : Vector.<Number> = new <Number> [     0,     // step * 0.2
                                                               100.0, // const
                                                               0.5,   // const
                                                               0.0];  // const

        private var fc2 : Vector.<Number> = new <Number> [      2.0, // pow
                                                                0,
                                                                0,
                                                                0
        ];

        public function WaveDistortEffect (width:uint = 512, height:uint = 512, sources:Vector.<DisplayObject> = null, persistent:Boolean = true)
        {
            super(width, height, sources, persistent);
        }

        override protected function getProgramName () : String
        {
            return "WaveDistortEffect2";
        }

        override protected function getFragmentProgramCode () : String
        {
            return [

                // ft1.x = sin((v0.y + t * 0.2) * 100.0) * tn;
                "add ft1.x, v0.y, fc1.x",
                "mul ft1.x, ft1.x, fc1.y",
                "sin ft1.x, ft1.x",
                "mul ft1.x, ft1.x, fc0.z",

                // dist = max(0.0, 0.5 - distance(Center Point, v0) / step ) ^ 2;
                "sub ft2.xy, fc0.xy, v0.xy",
                "abs ft2.xy, ft2.xy",
                "div ft2.xy, ft2.xy, fc0.ww",
                "sub ft2.xy, fc1.zz, ft2.xy",
                "max ft2.xy, fc1.ww, ft2.xy",
                "pow ft2.xy, ft2.xy, fc2.xx",

                // ft1.x = ft1.x * ft2.x * ft2.y
                "mul ft1.x, ft1.x, ft2.x",
                "mul ft1.x, ft1.x, ft2.y",

                // ft0.x = v0.x + ft1.x
                "mov ft0, v0",
                "add ft0.x, ft0.x, ft1.x",

                "tex oc, ft0, fs0 <2d,norepeat,linear>",
//                "tex ft2, ft0, fs0 <2d,norepeat,linear>\n",
//                "add ft2.r, ft2.r, fc1.z\nmov oc, ft2\n"
            ].join("\n");

        }

        override protected function onProgramReady (context : Context3D) : void
        {
            var strength:Number = Math.max(0, step > 0.5 ? 1.0 - step : step);

            fc0[0] = 0.5; //centerPoint.x / texture.width;
            fc0[1] = 0.5; //centerPoint.y / texture.height;
            fc0[2] = strength;
            fc0[3] = step;

            fc1[0] = step * 0.2;

//            fc2[0] = pow;

            context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 0, fc0, 1);
            context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 1, fc1, 1);
            context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 2, fc2, 1);

            super.onProgramReady (context);
        }
    }
}
