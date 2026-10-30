package com.rdx.fullscreen.usbhelper;

/** Pure display geometry. Decoder padding/stride must never be passed as visible size. */
public final class VideoGeometry {
    public final int codecWidth, codecHeight, activeWidth, activeHeight;
    public VideoGeometry(int codecWidth, int codecHeight, int activeWidth, int activeHeight) {
        if (codecWidth <= 0 || codecHeight <= 0 || activeWidth <= 0 || activeHeight <= 0
                || activeWidth > codecWidth || activeHeight > codecHeight)
            throw new IllegalArgumentException("Invalid codec/active geometry");
        this.codecWidth = codecWidth; this.codecHeight = codecHeight;
        this.activeWidth = activeWidth; this.activeHeight = activeHeight;
    }

    public Projection project(int decodedWidth, int decodedHeight, int viewWidth, int viewHeight) {
        if (viewWidth <= 0 || viewHeight <= 0) throw new IllegalArgumentException("View is not laid out");
        float left, top;
        String mode;
        if (decodedWidth == activeWidth && decodedHeight == activeHeight) {
            left = top = 0; mode = "DECODED_ACTIVE";
        } else if (decodedWidth == codecWidth && decodedHeight == codecHeight) {
            left = (codecWidth - activeWidth) / 2f;
            top = (codecHeight - activeHeight) / 2f;
            mode = "CENTERED_NEGOTIATED_MARGINS";
        } else {
            throw new IllegalArgumentException("Unexpected visible decoder size " + decodedWidth + "x" + decodedHeight);
        }
        float scale = Math.min((float)viewWidth / activeWidth, (float)viewHeight / activeHeight);
        float destinationLeft = (viewWidth - activeWidth * scale) / 2f;
        float destinationTop = (viewHeight - activeHeight * scale) / 2f;
        return new Projection(this, decodedWidth, decodedHeight, viewWidth, viewHeight,
            left, top, destinationLeft, destinationTop, scale, mode);
    }

    public static final class Projection {
        public final int decodedWidth, decodedHeight, viewWidth, viewHeight;
        public final float sourceLeft, sourceTop, destinationLeft, destinationTop;
        public final float scale, scaleX, scaleY, translateX, translateY;
        public final String mode;
        private final VideoGeometry geometry;
        private Projection(VideoGeometry geometry, int decodedWidth, int decodedHeight,
                int viewWidth, int viewHeight, float left, float top,
                float destinationLeft, float destinationTop, float scale, String mode) {
            this.geometry = geometry;
            this.decodedWidth = decodedWidth; this.decodedHeight = decodedHeight;
            this.viewWidth = viewWidth; this.viewHeight = viewHeight;
            sourceLeft = left; sourceTop = top;
            this.destinationLeft = destinationLeft; this.destinationTop = destinationTop;
            this.scale = scale; this.mode = mode;
            // TextureView initially maps the entire visible picture to its view bounds.
            // Undo that nonuniform mapping, then fit the active picture with uniform scale.
            scaleX = scale * decodedWidth / viewWidth;
            scaleY = scale * decodedHeight / viewHeight;
            translateX = destinationLeft - left * scale;
            translateY = destinationTop - top * scale;
        }
        public float[] matrixValues() {
            return new float[]{scaleX, 0, translateX, 0, scaleY, translateY, 0, 0, 1};
        }
        public float viewToActiveX(float x) { return clamp((x-destinationLeft)/scale, geometry.activeWidth-1); }
        public float viewToActiveY(float y) { return clamp((y-destinationTop)/scale, geometry.activeHeight-1); }
        private static float clamp(float value, float max) { return Math.max(0, Math.min(max, value)); }
    }
}
