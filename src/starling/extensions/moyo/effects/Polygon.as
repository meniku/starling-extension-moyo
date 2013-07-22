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
    import starling.utils.VertexData;

    /**
     * Polygon.
     *
     * @author Nils Kübler
     */
    public class Polygon extends DisplayObject
    {
        private static var PROGRAM_NAME : String = "polygon";

        private static function registerPrograms () : void
        {
            var target : Starling = Starling.current;
            if (target.hasProgram (
                    PROGRAM_NAME
            )) {
                return;
            } // already registered

            var vertexProgramCode : String =
                    "m44 op, va0, vc0 \n" + // 4x4 matrix transform to output space
                    "mul v0, va1, vc4 \n";  // multiply color with alpha and pass it to fragment shader

            var fragmentProgramCode : String =
                    "mov oc, v0";           // just forward incoming color

            var vertexProgramAssembler : AGALMiniAssembler = new AGALMiniAssembler ();
            vertexProgramAssembler.assemble (Context3DProgramType.VERTEX, vertexProgramCode);

            var fragmentProgramAssembler : AGALMiniAssembler = new AGALMiniAssembler ();
            fragmentProgramAssembler.assemble (Context3DProgramType.FRAGMENT, fragmentProgramCode);

            target.registerProgram (
                    PROGRAM_NAME, vertexProgramAssembler.agalcode,
                    fragmentProgramAssembler.agalcode
            );
        }

        // member variables:
        private var mVertexData : VertexData;
        private var mIndexData : Vector.<uint>;
        private var mVertexBuffer : VertexBuffer3D;
        private var mIndexBuffer : IndexBuffer3D;
        private var mNumEdges : uint;

        public function Polygon (radius : Number, numEdges : int = 6, color : uint = 0xffffff) : void
        {
            mNumEdges = numEdges;
            // code:
            mVertexData = new VertexData (numEdges + 1);
            mVertexData.setUniformColor (color);
            mVertexData.setPosition (numEdges, 0.0, 0.0); // center vertex

            for (var i : int = 0; i < numEdges; ++i) {
                var edge : Point = Point.polar (radius, i * 2 * Math.PI / numEdges);
                mVertexData.setPosition (i, edge.x, edge.y);
            }

            // code:
            mIndexData = new <uint>[];
            for (var i : int = 0; i < numEdges; ++i) {
                mIndexData.push (numEdges, i, (i + 1) % numEdges);
            }

            createBuffers ();
            registerPrograms ();

            Starling.current.addEventListener (Event.CONTEXT3D_CREATE, onContextCreated);
        }

        public override function dispose () : void
        {

        }

        // code:

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
            support.raiseDrawCount (
            ); // (2)

            var alphaVector : Vector.<Number> = new <Number>[1.0, 1.0, 1.0, alpha * this.alpha];

            var context : Context3D = Starling.context; // (3)
            if (context == null) {
                throw new MissingContextError (
                );
            }

            // apply the current blendmode (4)
            support.applyBlendMode (
                    false
            );

            // activate program (shader) and set the required attributes / constants (5)
            context.setProgram (
                    Starling.current.getProgram (
                            PROGRAM_NAME
                    )
            );
            context.setVertexBufferAt (
                    0, mVertexBuffer, VertexData.POSITION_OFFSET, Context3DVertexBufferFormat.FLOAT_2
            );
            context.setVertexBufferAt (
                    1, mVertexBuffer, VertexData.COLOR_OFFSET, Context3DVertexBufferFormat.FLOAT_4
            );
            context.setProgramConstantsFromMatrix (
                    Context3DProgramType.VERTEX, 0, support.mvpMatrix3D, true
            );
            context.setProgramConstantsFromVector (
                    Context3DProgramType.VERTEX, 4, alphaVector, 1
            );

            // finally: draw the object! (6)
            context.drawTriangles (
                    mIndexBuffer, 0, mNumEdges
            );

            // reset buffers (7)
            context.setVertexBufferAt (
                    0, null
            );
            context.setVertexBufferAt (
                    1, null
            );
        }

        private function createBuffers () : void
        {
            var context : Context3D = Starling.context;
            if (context == null) {
                throw new MissingContextError (
                );
            }

            if (mVertexBuffer) {
                mVertexBuffer.dispose (
                );
            }
            if (mIndexBuffer) {
                mIndexBuffer.dispose (
                );
            }

            mVertexBuffer = context.createVertexBuffer (
                    mVertexData.numVertices,
                    VertexData.ELEMENTS_PER_VERTEX
            );
            mVertexBuffer.uploadFromVector (
                    mVertexData.rawData, 0, mVertexData.numVertices
            );

            mIndexBuffer = context.createIndexBuffer (
                    mIndexData.length
            );
            mIndexBuffer.uploadFromVector (
                    mIndexData, 0, mIndexData.length
            );
        }

        private function onContextCreated (event : Event) : void
        {
            createBuffers ();
            registerPrograms ();
        }

    }
}
