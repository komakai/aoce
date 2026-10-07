package aoce.samples.aocencnntest;

import androidx.appcompat.app.AppCompatActivity;
import aoce.android.library.wrapper.GLVideoRender;
import butterknife.BindView;

import android.Manifest;
import android.content.pm.PackageManager;
import android.hardware.display.DisplayManager;
import android.opengl.GLSurfaceView;
import android.os.Bundle;

import aoce.samples.aocencnntest.R;

import aoce.android.library.xswig.*;
import aoce.android.library.wrapper.*;
import aoce.samples.aocencnntest.AoceManager;
import butterknife.ButterKnife;

public class MainActivity extends AppCompatActivity implements IGLCopyTexture {
    private GLVideoRender glVideoRender = null;
    private AoceManager aoceManager = null;

    static {
        System.loadLibrary("ncnn");
    }

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        glVideoRender = new GLVideoRender();
        GLSurfaceView glSurfaceView = findViewById(R.id.es_surface_view);
        glVideoRender.init(glSurfaceView, this);

        if (checkSelfPermission(Manifest.permission.CAMERA) !=
                PackageManager.PERMISSION_GRANTED) {
            requestPermissions(
                    new String[]{Manifest.permission.CAMERA},
                    1);
            return;
        }
    }

    @Override
    protected void onStart() {
        super.onStart();
        AoceWrapper.initPlatform();
        AoceWrapper.loadAoce();
        aoceManager = new AoceManager();
        aoceManager.initGraph();
        aoceManager.openCamera(this, true);
        aoceManager.setDisplayRotation(getDisplayRotation());
        DisplayManager displayManager = (DisplayManager) getSystemService(DISPLAY_SERVICE);
        displayManager.registerDisplayListener(displayListener, null);
    }

    private int getDisplayRotation() {
        return getWindowManager().getDefaultDisplay().getRotation();
    }

    // manifest里声明了configChanges,旋转时不重建activity,只调整画面方向.
    // 90度与270度之间直接切换不会触发onConfigurationChanged,所以监听display变化
    private final DisplayManager.DisplayListener displayListener = new DisplayManager.DisplayListener() {
        @Override
        public void onDisplayAdded(int displayId) {
        }

        @Override
        public void onDisplayRemoved(int displayId) {
        }

        @Override
        public void onDisplayChanged(int displayId) {
            if (aoceManager != null) {
                aoceManager.setDisplayRotation(getDisplayRotation());
            }
        }
    };

    @Override
    protected void onStop() {
        super.onStop();
        DisplayManager displayManager = (DisplayManager) getSystemService(DISPLAY_SERVICE);
        displayManager.unregisterDisplayListener(displayListener);
        aoceManager.closeCamera();
    }

    @Override
    public void copyTex(int textureId, int width, int height) {
       aoceManager.showGL(textureId, width, height);
    }
}