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
        public var step:Number = 0.0;                   // 0.0 -> 1.0

        public var strengthFactor:Number = 1.0;
        public var centerX:Number = 0.5;
        public var centerY:Number = 0.5;
        public var vibration:Number = 0.2;
        public var multiplier:Number = 100.0;
        public var extrusion:Number = 0.5;
        public var zero:Number = 0.0;
        public var xInputFactor:Number = 0.0;
        public var yInputFactor:Number = 1.0;
        public var xOutputFactor:Number = 1.0;
        public var yOutputFactor:Number = 0.0;

        private static var fc0 : Vector.<Number> = new <Number>[      0,   // CenterX
                                                                      0,   // CenterY
                                                                      0,   // Strength (0 - 0.5 - 0, interpolated over the animation length) * strengthFactor
                                                                      0];  // Step     (0 - 1, interpolated over the animation length)

        private static var fc1 : Vector.<Number> = new <Number> [     0.2,   // step * vibration
                                                                      100.0, // multiplier
                                                                      0.5,   // extrusion
                                                                      0.0];  // zero

        private static var fc2 : Vector.<Number> = new <Number> [      1.0, // x-factor for sin-input
                                                                       0,   // y-factor for sin-input
                                                                       1.0, // x-factor for the coordinate output
                                                                       0    // y-factor for the coordinate output
        ];

        public function WaveDistortEffect (width:uint = 512, height:uint = 512, sources:Vector.<DisplayObject> = null, centerPivot:Boolean = false, persistent:Boolean = false)
        {
            super(width, height, sources, centerPivot, persistent);
        }

        override protected function getProgramName () : String
        {
            return "WaveDistortEffect";
        }

        override protected function getFragmentProgramCode () : String
        {
            // based on my shader on ShaderToy:
            // https://www.shadertoy.com/view/XdfGz2
            return [
                // calculate the SIN-Input (ft0.z) based on
                // - the Y-position of the current pixel (v0.y)
                // - the X-position of the current pixel (v0.y)
                "mul ft0.x, v0.x, fc2.x",
                "mul ft0.y, v0.y, fc2.y",
                "add ft0.z, ft0.x, ft0.y",

                // Store some SIN-Value to 'ft1.x' based on:
                //  - the sin-input (ft0.z)
                //  - the step * ponny (fc1.x)
                //  - and some multiplier (fc1.y)
                "add ft1.x, ft0.z, fc1.x",
                "mul ft1.x, ft1.x, fc1.y",
                "sin ft1.x, ft1.x",
                "mul ft1.x, ft1.x, fc0.z",

                // Calculate the distance to the center of the texture, normalize it and pow it:
                //    dist = max(0.0, 0.5 - distance(Center Point, v0) / step ) ^ 2;
                // results are in ft2.xy
                "sub ft2.xy, fc0.xy, v0.xy",
                "abs ft2.xy, ft2.xy",
                "div ft2.xy, ft2.xy, fc0.ww",
                "sub ft2.xy, fc1.zz, ft2.xy",
                "max ft2.xy, fc1.ww, ft2.xy",

                // multiply the SIN-Value (ft1.x) with the distance to the center of the texture in both directions ( x and y )
                "mul ft1.x, ft1.x, ft2.x",
                "mul ft1.x, ft1.x, ft2.y",

                // calculate the output-offsets for the x and y based on
                // - the SIN-Value (ft1.x)
                // - and the output factors
                "mul ft2.x, ft1.x, fc2.z",
                "mul ft2.y, ft1.x, fc2.w",

                // finally add those values as offsets to our output pixels
                "mov ft0, v0",
                "add ft0.x, ft0.x, ft2.x",
                "add ft0.y, ft0.y, ft2.y",

                // finally output the texture
                "tex oc, ft0, fs0 <2d,norepeat,linear>",
            ].join("\n");

        }


        override protected function onProgramReady (context : Context3D) : void
        {
            var strength:Number = Math.max(0, step > 0.5 ? 1.0 - step : step) * strengthFactor;

            fc0[0] = centerX;
            fc0[1] = centerY;
            fc0[2] = strength;
            fc0[3] = step;

            fc1[0] = step * vibration;
            fc1[1] = multiplier;
            fc1[2] = extrusion;
            fc1[3] = zero;

            fc2[0] = xInputFactor;
            fc2[1] = yInputFactor;
            fc2[2] = xOutputFactor;
            fc2[3] = yOutputFactor;

            context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 0, fc0, 1);
            context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 1, fc1, 1);
            context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 2, fc2, 1);

            super.onProgramReady (context);
        }
    }
}
