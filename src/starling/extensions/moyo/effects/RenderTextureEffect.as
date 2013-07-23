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
    import starling.display.DisplayObject;
    import starling.display.Image;
    import starling.display.Sprite;
    import starling.errors.MissingContextError;
    import starling.events.Event;
    import starling.textures.RenderTexture;
    import starling.textures.Texture;
    import starling.utils.MatrixUtil;
    import starling.utils.VertexData;

    /**
     * RenderTextureEffect.
     *
     * @author Nils Kübler
     */
    public class RenderTextureEffect extends DisplayObject
    {
        private static var sHelperPoint:Point = new Point();

        private var mProgramName:String;

        private var mVertexData : VertexData;
        private var mIndexData : Vector.<uint>;
        private var mVertexBuffer : VertexBuffer3D;
        private var mIndexBuffer : IndexBuffer3D;
        private var mRenderTexture:RenderTexture;
        private var mTextureDrawn:Boolean;

        private var mPersistent: Boolean;
        private var mWidth:uint = 512;
        private var mHeight:uint = 512;
        private var mSources:Vector.<DisplayObject> = null;

        public function RenderTextureEffect (width:uint = 512, height:uint = 512, sources:Vector.<DisplayObject> = null, persistent:Boolean = true) : void
        {
            mProgramName = getProgramName();
            mSources = sources;
            mWidth = width;
            mHeight = height;

            mIndexData = new <uint>[];
            mIndexData.push(0, 1, 2);
            mIndexData.push(1, 2, 3);

            mPersistent = persistent;

            Starling.current.addEventListener (Event.CONTEXT3D_CREATE, onContextCreated);
            createRenderTexture();
            createVertexData();

            registerPrograms ();
            createBuffers ();
        }

        public function forceRedraw() : void {
            if(mTextureDrawn) {
                mTextureDrawn = false;
                if(mPersistent) {
                    mRenderTexture.clear();
                }
            }
        }

        //==============================================================================================================
        // Required Display Object methods
        //==============================================================================================================

        private function onContextCreated (event : Event) : void
        {
            registerPrograms ();
            createBuffers ();
            mTextureDrawn = false;
        }

        public override function dispose () : void
        {
            Starling.current.removeEventListener(Event.CONTEXT3D_CREATE, onContextCreated);
            mRenderTexture.dispose();
            mRenderTexture = null;
            mIndexBuffer.dispose();
            mIndexBuffer = null;
            mVertexBuffer.dispose();
            mVertexBuffer = null;

            super.dispose();
        }

        public override function getBounds (targetSpace : DisplayObject, resultRect : Rectangle = null) : Rectangle
        {
            if (resultRect == null) {
                resultRect = new Rectangle ();
            }
            var transformationMatrix : Matrix = getTransformationMatrix (targetSpace);
            MatrixUtil.transformCoords(transformationMatrix, mWidth, mHeight, sHelperPoint);
            resultRect.setTo(0, 0, sHelperPoint.x, sHelperPoint.y);
            return resultRect;
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

            drawToTexture();

            if(mTextureDrawn) {
                // apply the current blendmode (4)
                support.applyBlendMode ( false );

                // activate program (shader) and set the required attributes / constants (5)
                context.setProgram (Starling.current.getProgram (mProgramName));
                context.setVertexBufferAt(0, mVertexBuffer, VertexData.POSITION_OFFSET, Context3DVertexBufferFormat.FLOAT_2);
                context.setVertexBufferAt(1, mVertexBuffer, VertexData.TEXCOORD_OFFSET,  Context3DVertexBufferFormat.FLOAT_2);
                context.setProgramConstantsFromMatrix (Context3DProgramType.VERTEX, 0, support.mvpMatrix3D, true);
                context.setProgramConstantsFromVector (Context3DProgramType.VERTEX, 4, alphaVector, 1);

                onProgramReady(context);
                context.setTextureAt(0, mRenderTexture.base);

                // finally: draw the object! (6)
                context.drawTriangles (mIndexBuffer, 0, 2);

                // reset buffers (7)
                context.setTextureAt(0, null);
                context.setVertexBufferAt (1, null);
                context.setVertexBufferAt (0, null);

                onEffectRendered();
            }
        }


        //==============================================================================================================
        // Override in Subclass
        //==============================================================================================================

        /**
         * Override this when you.
         * \
         * @return name of the program
         */
        protected function getProgramName() : String {
            return "renderTextureEffect";
        }

        /**
         * Override this when you want to supply a custom vertex shader.
         *
         * Don't forget to also override getProgramName
         *
         * @return Fragment Shader Code.
         */
        protected function getVertexProgramCode() : String {
            return [
                "m44 op, va0, vc0", // 4x4 matrix transform to output space
                "mov v0, va1",      // store texture coordinate at v0
                "mov v1, vc4",      // store alpha vector at v1
            ].join("\n");
        }

        /**
         * this is usally overridden by all RenderTextureEffects .
         *
         * Don't forget to also override getProgramName
         *
         * @return Fragment Shader Code.
         */
        protected function getFragmentProgramCode() : String {
            return [
                "tex ft0, v0, fs0 <2d,clamp,linear>",   // store texture color at v0 to ft0
//                "mul oc, ft0, v1",                      // multiply ft0 with alpha vector v1 and store to output oc
                "add oc, ft0, v1",                      // Blend a bit for test reasons
            ].join("\n");
        }


        /**
         * Override this if you want to set something additional before rendering the programs
         */
        protected function onProgramReady (context : Context3D) : void
        {

        }


        /**
         * Override this if you want to do something additional when the texture changes
         */
        protected function onTextureDrawn() : void {

        }

        /**
         * Override this if you want to do something additional after rendering the programs is completed
         */
        protected function onEffectRendered() : void {

        }

        //==============================================================================================================
        // Private Methods
        //==============================================================================================================

        private function registerPrograms () : void
        {
            var target : Starling = Starling.current;
            if (target.hasProgram (mProgramName)) {
                return;
            } // already registered

            var vertexProgramAssembler : AGALMiniAssembler = new AGALMiniAssembler ();
            vertexProgramAssembler.assemble (Context3DProgramType.VERTEX, getVertexProgramCode());

            var fragmentProgramAssembler : AGALMiniAssembler = new AGALMiniAssembler ();
            fragmentProgramAssembler.assemble (Context3DProgramType.FRAGMENT, getFragmentProgramCode());

            target.registerProgram (mProgramName, vertexProgramAssembler.agalcode, fragmentProgramAssembler.agalcode);
        }

        private function drawToTexture () : void
        {
            if(mSources && mSources.length) {
                if(!mTextureDrawn || !mPersistent) {
                    mRenderTexture.drawBundled(function():void {
                        var l:uint = mSources.length;
                        for (var i:int=0; i<l; ++i) {
                            var mat:Matrix = getTransformationMatrix(mSources[i]);
                            mat.invert();
                            mRenderTexture.draw(mSources[i], mat);
                        }
                    });
                    onTextureDrawn();

                    mTextureDrawn = true;
                }
            } else {
                forceRedraw();
            }
        }

        private function createVertexData() : void
        {
            mVertexData = new VertexData (4);
            mVertexData.setPosition(0, 0.0, 0.0);
            mVertexData.setPosition(1, mWidth, 0.0);
            mVertexData.setPosition(2, 0.0, mHeight);
            mVertexData.setPosition(3, mWidth, mHeight);
            mVertexData.setTexCoords(0, 0.0, 0.0);
            mVertexData.setTexCoords(1, 1.0, 0.0);
            mVertexData.setTexCoords(2, 0.0, 1.0);
            mVertexData.setTexCoords(3, 1.0, 1.0);
        }

        private function createRenderTexture() : void {
            if(mRenderTexture) {
                mRenderTexture.dispose();
            }
            mRenderTexture = new RenderTexture(mWidth, mHeight, mPersistent);
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

        // TODO: call this whenever width/height changes
        private function onResized() : void {
            createRenderTexture();
            createVertexData();
            forceRedraw();
        }

        //==============================================================================================================
        // Properties
        //==============================================================================================================

        public function get persistent () : Boolean
        {
            return mPersistent;
        }

        public function set persistent (value : Boolean) : void
        {
            mPersistent = value;
        }

        public function get sources () : Vector.<DisplayObject>
        {
            return mSources;
        }

        public function set sources (value : Vector.<DisplayObject>) : void
        {
            mSources = value;
            forceRedraw();
        }
    }
}
