import com.rdx.fullscreen.usbhelper.VideoGeometry;
import java.util.Random;

public final class VideoGeometryTest {
    private static int checks;
    private static void check(boolean condition) {
        checks++;
        if (!condition) throw new AssertionError("Geometry check " + checks);
    }
    private static void near(float expected, float actual) { check(Math.abs(expected-actual) < 0.01f); }
    // Apply the same matrix values passed to Android Matrix, after TextureView's base mapping.
    private static float[] display(VideoGeometry.Projection p, float sourceX, float sourceY) {
        float x=sourceX*p.viewWidth/p.decodedWidth, y=sourceY*p.viewHeight/p.decodedHeight;
        float[] m=p.matrixValues();
        return new float[]{m[0]*x+m[1]*y+m[2],m[3]*x+m[4]*y+m[5]};
    }
    private static void position(VideoGeometry.Projection p, float sx, float sy, float x, float y) {
        float[] result=display(p,sx,sy); near(x,result[0]); near(y,result[1]);
    }
    private static void reject(Runnable action) {
        boolean rejected=false;
        try { action.run(); } catch (IllegalArgumentException expected) { rejected=true; }
        check(rejected);
    }
    public static void main(String[] args) {
        VideoGeometry full=new VideoGeometry(1920,1080,1920,720);
        VideoGeometry.Projection p=full.project(1920,1080,1920,720);
        near(1,p.scaleX); near(1.5f,p.scaleY); near(0,p.translateX); near(-180,p.translateY);
        position(p,0,180,0,0); position(p,1920,900,1920,720); position(p,960,540,960,360);
        check(display(p,0,0)[1]<0); check(display(p,0,1080)[1]>720);
        near(960,p.viewToActiveX(960)); near(360,p.viewToActiveY(360));
        near(1919,p.viewToActiveX(1920)); near(719,p.viewToActiveY(720));
        VideoGeometry.Projection active=full.project(1920,720,1920,720);
        check("DECODED_ACTIVE".equals(active.mode));
        near(1,active.scaleX); near(1,active.scaleY); near(0,active.translateY);
        position(active,0,0,0,0); position(active,1920,720,1920,720);

        VideoGeometry fallback=new VideoGeometry(800,480,800,430);
        VideoGeometry.Projection f=fallback.project(800,480,1920,720);
        position(f,0,25,(1920-800*720f/430)/2,0);
        position(f,800,455,(1920+800*720f/430)/2,720);
        near(0,f.viewToActiveX(0)); near(799,f.viewToActiveX(1920));
        near(400,f.viewToActiveX(960)); near(215,f.viewToActiveY(360));

        VideoGeometry.Projection resized=full.project(1920,1080,1339,720);
        position(resized,960,540,669.5f,360);
        near((720-720*1339f/1920)/2,resized.destinationTop);
        VideoGeometry.Projection none=new VideoGeometry(1280,720,1280,720).project(1280,720,1920,1080);
        near(1,none.scaleX); near(1,none.scaleY); position(none,1280,720,1920,1080);
        VideoGeometry.Projection odd=new VideoGeometry(1921,1081,1920,720).project(1921,1081,1920,720);
        position(odd,0.5f,180.5f,0,0); position(odd,1920.5f,900.5f,1920,720);

        reject(new Runnable(){public void run(){new VideoGeometry(0,1080,1920,720);}});
        reject(new Runnable(){public void run(){new VideoGeometry(1920,1080,1921,720);}});
        reject(new Runnable(){public void run(){new VideoGeometry(1920,1080,1920,-1);}});
        reject(new Runnable(){public void run(){new VideoGeometry(1920,1080,1920,720).project(2048,1184,1920,720);}});
        reject(new Runnable(){public void run(){new VideoGeometry(1920,1080,1920,720).project(1920,1080,0,720);}});

        // Different margins, aspect ratios, resizes, and already-active output.
        Random random=new Random(20261030L);
        for(int i=0;i<200;i++) {
            int aw=100+random.nextInt(1900), ah=100+random.nextInt(1000);
            int cw=aw+random.nextInt(300), ch=ah+random.nextInt(400);
            int vw=300+random.nextInt(1800), vh=300+random.nextInt(1000);
            VideoGeometry g=new VideoGeometry(cw,ch,aw,ah);
            VideoGeometry.Projection r=g.project(i%2==0?cw:aw,i%2==0?ch:ah,vw,vh);
            position(r,r.sourceLeft,r.sourceTop,r.destinationLeft,r.destinationTop);
            position(r,r.sourceLeft+aw/2f,r.sourceTop+ah/2f,vw/2f,vh/2f);
            float[] a=display(r,r.sourceLeft,r.sourceTop), b=display(r,r.sourceLeft+10,r.sourceTop+10);
            near(b[0]-a[0],b[1]-a[1]); // equal horizontal/vertical source pixels stay equal
            near(aw/2f,r.viewToActiveX(vw/2f)); near(ah/2f,r.viewToActiveY(vh/2f));
            check(r.destinationLeft>=-0.01f && r.destinationTop>=-0.01f);
            near(0,r.viewToActiveX(-100)); near(ah-1,r.viewToActiveY(vh+100));
        }
        System.out.println("PASS: "+checks+" geometry and diagnostic touch-mapping checks");
    }
}
