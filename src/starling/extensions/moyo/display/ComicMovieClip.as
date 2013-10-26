/*
 * Copyright 2013 by Didgeridoo Unlimited.
 */
package starling.extensions.moyo.display
{
    import com.adobe.utils.AGALMiniAssembler;
    import flash.display3D.*;
    import flash.errors.IllegalOperationError;
    import flash.geom.*;
    import flash.media.Sound;

    import starling.animation.IAnimatable;

    import starling.core.RenderSupport;
    import starling.core.Starling;
    import starling.display.DisplayObject;
    import starling.errors.MissingContextError;
    import starling.events.Event;
    import starling.extensions.moyo.shaders.ComicShader;
    import starling.textures.Texture;
    import starling.utils.MatrixUtil;
    import starling.utils.VertexData;

    /**
     * ComicMovieClip.
     *
     * @author Nils Kübler
     */
    public class ComicMovieClip extends DisplayObject implements IAnimatable
    {
        private static var sHelperPoint : Point = new Point ();

//        private var mProgramName:String = "comic";

        private var mShader:ComicShader = new ComicShader();

        private var mIndexData : Vector.<uint>;
        private var mVertexData : VertexData;
        private var mVertexBuffer : VertexBuffer3D;
        private var mIndexBuffer : IndexBuffer3D;

        private var mCurrentTexture:Texture;
        private var mTextures:Vector.<Texture>;
        private var mSounds:Vector.<Sound>;
        private var mDurations:Vector.<Number>;
        private var mStartTimes:Vector.<Number>;

        private var mDefaultFrameDuration:Number;
        private var mCurrentTime:Number;
        private var mCurrentFrame:int;
        private var mLoop:Boolean;
        private var mPlaying:Boolean;

        private var mWidth : uint = 512;
        private var mHeight : uint = 512;

        /** Creates a movie clip from the provided textures and with the specified default framerate.
         *  The movie will have the size of the first frame. */
        public function ComicMovieClip(textures:Vector.<Texture>, fps:Number=12)
        {
            if (textures.length > 0)
            {
                init(textures, fps);
            }
            else
            {
                throw new ArgumentError("Empty texture array");
            }
        }

        private function init(textures:Vector.<Texture>, fps:Number):void
        {
            if (fps <= 0) throw new ArgumentError("Invalid fps: " + fps);

            var firstTexture:Texture = textures[0];
            var frame:Rectangle = firstTexture.frame;
            mWidth  = frame ? frame.width  : firstTexture.width;
            mHeight = frame ? frame.height : firstTexture.height;

            mIndexData = new <uint>[];
            mIndexData.push (0, 1, 2);
            mIndexData.push (1, 2, 3);

            var numFrames:int = textures.length;

            mDefaultFrameDuration = 1.0 / fps;
            mLoop = true;
            mPlaying = true;
            mCurrentTime = 0.0;
            mCurrentFrame = 0;
            mTextures = textures.concat();
            mSounds = new Vector.<Sound>(numFrames);
            mDurations = new Vector.<Number>(numFrames);
            mStartTimes = new Vector.<Number>(numFrames);

            for (var i:int=0; i<numFrames; ++i)
            {
                mDurations[i] = mDefaultFrameDuration;
                mStartTimes[i] = i * mDefaultFrameDuration;
            }

            Starling.current.addEventListener (Event.CONTEXT3D_CREATE, onContextCreated);
            createVertexData ();

            registerPrograms ();
            createBuffers ();
        }

        // frame manipulation

        /** Adds an additional frame, optionally with a sound and a custom duration. If the
         *  duration is omitted, the default framerate is used (as specified in the constructor). */
        public function addFrame(texture:Texture, sound:Sound=null, duration:Number=-1):void
        {
            addFrameAt(numFrames, texture, sound, duration);
        }

        /** Adds a frame at a certain index, optionally with a sound and a custom duration. */
        public function addFrameAt(frameID:int, texture:Texture, sound:Sound=null,
                                   duration:Number=-1):void
        {
            if (frameID < 0 || frameID > numFrames) throw new ArgumentError("Invalid frame id");
            if (duration < 0) duration = mDefaultFrameDuration;

            mTextures.splice(frameID, 0, texture);
            mSounds.splice(frameID, 0, sound);
            mDurations.splice(frameID, 0, duration);

            if (frameID > 0 && frameID == numFrames)
                mStartTimes[frameID] = mStartTimes[int(frameID-1)] + mDurations[int(frameID-1)];
            else
                updateStartTimes();
        }

        /** Removes the frame at a certain ID. The successors will move down. */
        public function removeFrameAt(frameID:int):void
        {
            if (frameID < 0 || frameID >= numFrames) throw new ArgumentError("Invalid frame id");
            if (numFrames == 1) throw new IllegalOperationError("Movie clip must not be empty");

            mTextures.splice(frameID, 1);
            mSounds.splice(frameID, 1);
            mDurations.splice(frameID, 1);

            updateStartTimes();
        }

        /** Returns the texture of a certain frame. */
        public function getFrameTexture(frameID:int):Texture
        {
            if (frameID < 0 || frameID >= numFrames) throw new ArgumentError("Invalid frame id");
            return mTextures[frameID];
        }

        /** Sets the texture of a certain frame. */
        public function setFrameTexture(frameID:int, texture:Texture):void
        {
            if (frameID < 0 || frameID >= numFrames) throw new ArgumentError("Invalid frame id");
            mTextures[frameID] = texture;
        }

        /** Returns the sound of a certain frame. */
        public function getFrameSound(frameID:int):Sound
        {
            if (frameID < 0 || frameID >= numFrames) throw new ArgumentError("Invalid frame id");
            return mSounds[frameID];
        }

        /** Sets the sound of a certain frame. The sound will be played whenever the frame
         *  is displayed. */
        public function setFrameSound(frameID:int, sound:Sound):void
        {
            if (frameID < 0 || frameID >= numFrames) throw new ArgumentError("Invalid frame id");
            mSounds[frameID] = sound;
        }

        /** Returns the duration of a certain frame (in seconds). */
        public function getFrameDuration(frameID:int):Number
        {
            if (frameID < 0 || frameID >= numFrames) throw new ArgumentError("Invalid frame id");
            return mDurations[frameID];
        }

        /** Sets the duration of a certain frame (in seconds). */
        public function setFrameDuration(frameID:int, duration:Number):void
        {
            if (frameID < 0 || frameID >= numFrames) throw new ArgumentError("Invalid frame id");
            mDurations[frameID] = duration;
            updateStartTimes();
        }

        // playback methods

        /** Starts playback. Beware that the clip has to be added to a juggler, too! */
        public function play():void
        {
            mPlaying = true;
        }

        /** Pauses playback. */
        public function pause():void
        {
            mPlaying = false;
        }

        /** Stops playback, resetting "currentFrame" to zero. */
        public function stop():void
        {
            mPlaying = false;
            currentFrame = 0;
        }

        // helpers

        private function updateStartTimes():void
        {
            var numFrames:int = this.numFrames;

            mStartTimes.length = 0;
            mStartTimes[0] = 0;

            for (var i:int=1; i<numFrames; ++i)
                mStartTimes[i] = mStartTimes[int(i-1)] + mDurations[int(i-1)];
        }

        // IAnimatable

        /** @inheritDoc */
        public function advanceTime(passedTime:Number):void
        {
            if (!mPlaying || passedTime <= 0.0) return;

            var finalFrame:int;
            var previousFrame:int = mCurrentFrame;
            var restTime:Number = 0.0;
            var breakAfterFrame:Boolean = false;
            var hasCompleteListener:Boolean = hasEventListener(Event.COMPLETE);
            var dispatchCompleteEvent:Boolean = false;
            var totalTime:Number = this.totalTime;

            if (mLoop && mCurrentTime >= totalTime)
            {
                mCurrentTime = 0.0;
                mCurrentFrame = 0;
            }

            if (mCurrentTime < totalTime)
            {
                mCurrentTime += passedTime;
                finalFrame = mTextures.length - 1;

                while (mCurrentTime > mStartTimes[mCurrentFrame] + mDurations[mCurrentFrame])
                {
                    if (mCurrentFrame == finalFrame)
                    {
                        if (mLoop && !hasCompleteListener)
                        {
                            mCurrentTime -= totalTime;
                            mCurrentFrame = 0;
                        }
                        else
                        {
                            breakAfterFrame = true;
                            restTime = mCurrentTime - totalTime;
                            dispatchCompleteEvent = hasCompleteListener;
                            mCurrentFrame = finalFrame;
                            mCurrentTime = totalTime;
                        }
                    }
                    else
                    {
                        mCurrentFrame++;
                    }

                    var sound:Sound = mSounds[mCurrentFrame];
                    if (sound) sound.play();
                    if (breakAfterFrame) break;
                }

                // special case when we reach *exactly* the total time.
                if (mCurrentFrame == finalFrame && mCurrentTime == totalTime)
                    dispatchCompleteEvent = hasCompleteListener;
            }

            if (mCurrentFrame != previousFrame)
                mCurrentTexture = mTextures[mCurrentFrame];

            if (dispatchCompleteEvent)
                dispatchEventWith(Event.COMPLETE);

            if (mLoop && restTime > 0.0)
                advanceTime(restTime);
        }

        /** Indicates if a (non-looping) movie has come to its end. */
        public function get isComplete():Boolean
        {
            return !mLoop && mCurrentTime >= totalTime;
        }

        // properties

        /** The total duration of the clip in seconds. */
        public function get totalTime():Number
        {
            var numFrames:int = mTextures.length;
            return mStartTimes[int(numFrames-1)] + mDurations[int(numFrames-1)];
        }

        /** The time that has passed since the clip was started (each loop starts at zero). */
        public function get currentTime():Number { return mCurrentTime; }

        /** The total number of frames. */
        public function get numFrames():int { return mTextures.length; }

        /** Indicates if the clip should loop. */
        public function get loop():Boolean { return mLoop; }
        public function set loop(value:Boolean):void { mLoop = value; }

        /** The index of the frame that is currently displayed. */
        public function get currentFrame():int { return mCurrentFrame; }
        public function set currentFrame(value:int):void
        {
            mCurrentFrame = value;
            mCurrentTime = 0.0;

            for (var i:int=0; i<value; ++i)
                mCurrentTime += getFrameDuration(i);

            mCurrentTexture = mTextures[mCurrentFrame];
            if (mSounds[mCurrentFrame]) mSounds[mCurrentFrame].play();
        }

        /** The default number of frames per second. Individual frames can have different
         *  durations. If you change the fps, the durations of all frames will be scaled
         *  relatively to the previous value. */
        public function get fps():Number { return 1.0 / mDefaultFrameDuration; }
        public function set fps(value:Number):void
        {
            if (value <= 0) throw new ArgumentError("Invalid fps: " + value);

            var newFrameDuration:Number = 1.0 / value;
            var acceleration:Number = newFrameDuration / mDefaultFrameDuration;
            mCurrentTime *= acceleration;
            mDefaultFrameDuration = newFrameDuration;

            for (var i:int=0; i<numFrames; ++i)
            {
                var duration:Number = mDurations[i] * acceleration;
                mDurations[i] = duration;
            }

            updateStartTimes();
        }

        /** Indicates if the clip is still playing. Returns <code>false</code> when the end
         *  is reached. */
        public function get isPlaying():Boolean
        {
            if (mPlaying)
                return mLoop || mCurrentTime < totalTime;
            else
                return false;
        }

        public override function getBounds (targetSpace : DisplayObject, resultRect : Rectangle = null) : Rectangle
        {
            if (resultRect == null) {
                resultRect = new Rectangle ();
            }
            var transformationMatrix : Matrix = getTransformationMatrix (targetSpace);
            MatrixUtil.transformCoords (transformationMatrix, mWidth, mHeight, sHelperPoint);
            resultRect.setTo (0, 0, sHelperPoint.x, sHelperPoint.y);
            return resultRect;
        }

        public override function render (support : RenderSupport, alpha : Number) : void
        {
            // always call this method when you write custom rendering code!
            // it causes all previously batched quads/images to render.
            support.finishQuadBatch (); // (1)

            // make this call to keep the statistics display in sync.
            support.raiseDrawCount (); // (2)

            var alphaVector : Vector.<Number> = new <Number>[1.0, 1.0, 1.0, alpha * this.alpha];
            var paramVector : Vector.<Number> = new <Number>[0.02,     // extrusion
                                                             0.0000000001, // alpha threhold
                                                             1.0, 0.0];

            var extrusionVector:Vector.<Number> = new <Number>[-0.02, +0.02, 0.0, 1.0];

            var outlineColor : Vector.<Number> = new <Number>[0.0, 0.0, 0.0, 1.0];


            var context : Context3D = Starling.context; // (3)
            if (context == null) {
                throw new MissingContextError ();
            }

            if(mCurrentTexture) {
                support.applyBlendMode (false);

                context.setProgram (mShader.program);
                context.setVertexBufferAt (0, mVertexBuffer, VertexData.POSITION_OFFSET, Context3DVertexBufferFormat.FLOAT_2);
                context.setVertexBufferAt (1, mVertexBuffer, VertexData.TEXCOORD_OFFSET, Context3DVertexBufferFormat.FLOAT_2);
                context.setProgramConstantsFromMatrix (Context3DProgramType.VERTEX, 0, support.mvpMatrix3D, true);
                context.setProgramConstantsFromVector (Context3DProgramType.VERTEX, 4, alphaVector, 1);
                context.setProgramConstantsFromVector (Context3DProgramType.VERTEX, 5, extrusionVector, 1);
                context.setProgramConstantsFromVector (Context3DProgramType.FRAGMENT, 0, paramVector, 1);
                context.setProgramConstantsFromVector (Context3DProgramType.FRAGMENT, 1, outlineColor, 1);

                context.setTextureAt (0, mCurrentTexture.base);
                context.drawTriangles (mIndexBuffer, 0, 2);

                context.setTextureAt (0, null);
                context.setVertexBufferAt (1, null);
                context.setVertexBufferAt (0, null);
            }
        }

        //==============================================================================================================
        // Required Display Object methods
        //==============================================================================================================

        private function onContextCreated (event : Event) : void
        {
            registerPrograms ();
            createBuffers ();
        }

        public override function dispose () : void
        {
            Starling.current.removeEventListener (Event.CONTEXT3D_CREATE, onContextCreated);

            mShader.dispose();
            mShader = null;
            mIndexBuffer.dispose ();
            mIndexBuffer = null;
            mVertexBuffer.dispose ();
            mVertexBuffer = null;

            super.dispose ();
        }

        //==============================================================================================================
        // Private Methods
        //==============================================================================================================

        private function registerPrograms () : void
        {
            mShader.upload(Starling.context);
        }


        private function createVertexData () : void
        {
            mVertexData = new VertexData (4);
            mVertexData.setPosition (0, 0.0, 0.0);
            mVertexData.setPosition (1, mWidth, 0.0);
            mVertexData.setPosition (2, 0.0, mHeight);
            mVertexData.setPosition (3, mWidth, mHeight);
            mVertexData.setTexCoords (0, 0.0, 0.0);
            mVertexData.setTexCoords (1, 1.0, 0.0);
            mVertexData.setTexCoords (2, 0.0, 1.0);
            mVertexData.setTexCoords (3, 1.0, 1.0);
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

            mVertexBuffer = context.createVertexBuffer (mVertexData.numVertices, VertexData.ELEMENTS_PER_VERTEX);
            mVertexBuffer.uploadFromVector (mVertexData.rawData, 0, 4);

            mIndexBuffer = context.createIndexBuffer (mIndexData.length);
            mIndexBuffer.uploadFromVector (mIndexData, 0, 6);
        }
    }
}
