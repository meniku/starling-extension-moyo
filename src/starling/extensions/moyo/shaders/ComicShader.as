/*
 * Copyright 2013 by Didgeridoo Unlimited.
 */
package starling.extensions.moyo.shaders
{
    import com.barliesque.agal.EasierAGAL;
    import com.barliesque.agal.TextureFlag;

    /**
     * ComicShader.
     *
     * @author Nils Kübler
     */
    public class ComicShader extends EasierAGAL
    {
        override protected function _vertexShader () : void
        {
            multiply4x4(OUTPUT, ATTRIBUTE[0], CONST[0]);
            move(VARYING[0], ATTRIBUTE[1]);

            add(VARYING[1], ATTRIBUTE[1], CONST[5]._("xxww"));
            add(VARYING[2], ATTRIBUTE[1], CONST[5]._("yyww"));
            add(VARYING[3], ATTRIBUTE[1], CONST[5]._("xyww"));
            add(VARYING[4], ATTRIBUTE[1], CONST[5]._("yxww"));

            move(VARYING[5], CONST[4]);
        }

        override protected function _fragmentShader () : void
        {
            sampleTexture(TEMP[0], VARYING[0], SAMPLER[0], [TextureFlag.TYPE_2D, TextureFlag.MODE_CLAMP, TextureFlag.FILTER_LINEAR]);

            sampleStep(1);
            sampleStep(2);
            sampleStep(3);
            sampleStep(4);

            // add alpha
            multiply(OUTPUT, TEMP[0], VARYING[5]);
        }

        private function sampleStep (varying:uint) : void
        {
            sampleTexture (TEMP[1], VARYING[varying], SAMPLER[0], [ TextureFlag.TYPE_2D, TextureFlag.MODE_CLAMP, TextureFlag.FILTER_NEAREST, TextureFlag.FILTER_LINEAR ]);

            // texture color
            add (TEMP[2].a, TEMP[0].a, TEMP[1].a);
            setIf_GreaterEqual (TEMP[2], TEMP[2].a, CONST[0].y);
            multiply (TEMP[2], TEMP[2], TEMP[0]);

            // outline color
            subtract (TEMP[3].a, TEMP[1].a, TEMP[0].a);
            setIf_GreaterEqual (TEMP[3], TEMP[3].a, CONST[0].y);
            multiply (TEMP[3], TEMP[3], CONST[1]);
            move (TEMP[3].a, TEMP[1].a);

            // combine texture and outline color
            add (TEMP[0], TEMP[2], TEMP[3]);
        }
    }
}
