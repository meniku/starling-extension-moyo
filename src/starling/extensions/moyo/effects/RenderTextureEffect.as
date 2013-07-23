/*
 * Copyright 2013 by Didgeridoo Unlimited.
 */
package starling.extensions.moyo.effects
{
    import com.adobe.utils.AGALMiniAssembler;

    import flash.display3D.Context3D;
    import flash.display3D.Context3DProgramType;
    import flash.display3D.Context3DVertexBufferFormat;
    import flash.display3D.IndexBuffer3D;
    import flash.display3D.VertexBuffer3D;
    import flash.geom.Matrix;
    import flash.geom.Point;
    import flash.geom.Rectangle;

    import starling.core.RenderSupport;
    import starling.core.Starling;
    import starling.display.DisplayObject;
    import starling.errors.MissingContextError;
    import starling.events.Event;
    import starling.textures.Texture;
    import starling.utils.VertexData;

    /**
     * Polygon.
     *
     * @author Nils Kübler
     */
    public class RenderTextureEffect extends DisplayObject
    {
        private static var PROGRAM_NAME : String = "rendertexture";

        private static function registerPrograms () : void
        {
            var target : Starling = Starling.current;
            if (target.hasProgram (PROGRAM_NAME)) {
                return;
            } // already registered

            var vertexProgramCode : String = [
                "m44 op, va0, vc0", // 4x4 matrix transform to output space
                "mov v0, va1",      // store texture coordinate at v0
                "mov v1, vc4",      // store alpha vector at v1
            ].join("\n");

            var fragmentProgramCode : String = [
                "tex ft0, v0, fs0 <2d,clamp,linear>",   // store texture color at v0 to ft0
                "mul oc, ft0, v1",                      // multiply ft0 with alpha vector v1 and store to output oc
            ].join("\n");

            var vertexProgramAssembler : AGALMiniAssembler = new AGALMiniAssembler ();
            vertexProgramAssembler.assemble (Context3DProgramType.VERTEX, vertexProgramCode);

            var fragmentProgramAssembler : AGALMiniAssembler = new AGALMiniAssembler ();
            fragmentProgramAssembler.assemble (Context3DProgramType.FRAGMENT, fragmentProgramCode);

            target.registerProgram (PROGRAM_NAME, vertexProgramAssembler.agalcode, fragmentProgramAssembler.agalcode);
        }

        private var mVertexData : VertexData;
        private var mIndexData : Vector.<uint>;
        private var mVertexBuffer : VertexBuffer3D;
        private var mIndexBuffer : IndexBuffer3D;

        [Embed(source="/images/tex.jpg")]
        public static const TextureImage : Class;

        private var  texture : Texture = Texture.fromBitmap (new TextureImage ());

        public function RenderTextureEffect (width:uint = 512, height:uint = 512) : void
        {
            mVertexData = new VertexData (4);
            mVertexData.setPosition(0, 0.0, 0.0);
            mVertexData.setPosition(1, width, 0.0);
            mVertexData.setPosition(2, 0.0, height);
            mVertexData.setPosition(3, width, height);
            mVertexData.setTexCoords(0, 0.0, 0.0);
            mVertexData.setTexCoords(1, 1.0, 0.0);
            mVertexData.setTexCoords(2, 0.0, 1.0);
            mVertexData.setTexCoords(3, 1.0, 1.0);

            mIndexData = new <uint>[];
            mIndexData.push(0, 1, 2);
            mIndexData.push(1, 2, 3);

            Starling.current.addEventListener (Event.CONTEXT3D_CREATE, onContextCreated);
            registerPrograms ();
            createBuffers ();
        }

        private function onContextCreated (event : Event) : void
        {
            registerPrograms ();
            createBuffers ();
        }

        public override function dispose () : void
        {
            Starling.current.removeEventListener(Event.CONTEXT3D_CREATE, onContextCreated);
        }

        public override function getBounds (targetSpace : DisplayObject, resultRect : Rectangle = null) : Rectangle
        {
            if (resultRect == null) {
                resultRect = new Rectangle ();
            }
            var transformationMatrix : Matrix = getTransformationMatrix (targetSpace);
            return mVertexData.getBounds (transformationMatrix, 0, -1, resultRect);
        }

        public override function render (support : RenderSupport, alpha : Number) : void
        {
            // always call this method when you write custom rendering code!
            // it causes all previously batched quads/images to render.
            support.finishQuadBatch (); // (1)

            // make this call to keep the statistics display in sync.
            support.raiseDrawCount ( ); // (2)

            var alphaVector : Vector.<Number> = new <Number>[1.0, 1.0, 1.0, alpha * this.alpha];

            var context : Context3D = Starling.context; // (3)
            if (context == null) {
                throw new MissingContextError ( );
            }

            // apply the current blendmode (4)
            support.applyBlendMode ( false );

            // activate program (shader) and set the required attributes / constants (5)
            context.setProgram (Starling.current.getProgram (PROGRAM_NAME));
            context.setVertexBufferAt(0, mVertexBuffer, VertexData.POSITION_OFFSET, Context3DVertexBufferFormat.FLOAT_2);
            context.setVertexBufferAt(1, mVertexBuffer, VertexData.TEXCOORD_OFFSET,  Context3DVertexBufferFormat.FLOAT_2);
            context.setProgramConstantsFromMatrix (Context3DProgramType.VERTEX, 0, support.mvpMatrix3D, true);
            context.setProgramConstantsFromVector (Context3DProgramType.VERTEX, 4, alphaVector, 1);
            context.setTextureAt(0, texture.base);

            // finally: draw the object! (6)
            context.drawTriangles (mIndexBuffer, 0, 2);

            // reset buffers (7)
            context.setTextureAt(0, null);
            context.setVertexBufferAt (1, null);
            context.setVertexBufferAt (0, null);
        }

        private function createBuffers () : void
        {
            var context : Context3D = Starling.context;
            if (context == null) {
                throw new MissingContextError ();
            }

            if (mVertexBuffer) {
                mVertexBuffer.dispose ();
            }
            if (mIndexBuffer) {
                mIndexBuffer.dispose ();
            }

            mVertexBuffer = context.createVertexBuffer (mVertexData.numVertices,VertexData.ELEMENTS_PER_VERTEX);
            mVertexBuffer.uploadFromVector (mVertexData.rawData, 0, 4);

            mIndexBuffer = context.createIndexBuffer (mIndexData.length);
            mIndexBuffer.uploadFromVector (mIndexData, 0, 6);
        }
    }
}
