package aoce.samples.aocencnntest;

import android.content.Context;
import android.hardware.camera2.CameraAccessException;
import android.hardware.camera2.CameraCharacteristics;
import android.hardware.camera2.CameraManager;
import android.view.Surface;

import java.util.ArrayList;
import java.util.List;

import aoce.android.library.xswig.*;

public class AoceManager extends IVideoDeviceObserver {
    private IPipeGraph pipeGraph = null;
    private LayerFactory layerFactory = null;
    private IInputLayer inputLayer = null;
    private IOutputLayer outputLayer = null;
    private IYUVLayer yuv2RGBALayer = null;   ;
    private ITransposeLayer transposeLayerNcnn = null;
    // 没有转置时(横屏)用来翻转方向
    private IFlipLayer orientFlipLayer = null;
    private ITransposeLayer transposeLayer = null;
    private IFlipLayer flipLayer = null;
    private IReSizeLayer reSizeLayer = null;
    private IBaseLayer extraLayer = null;
    private IVideoDevice videoDevice = null;
    private VideoFormat videoFormat = null;
    private GLOutGpuTex gpuTex = new GLOutGpuTex();

    private IFaceDetector faceDetector = null;
    private IFaceKeypointDetector faceKeypointDetector = null;
    private IBaseLayer ncnnInLayer = null;
    private INcnnInCropLayer ncnnInCropLayer = null;
    private IDrawRectLayer drawRectLayer = null;
    private IDrawPointsLayer drawPointsLayer = null;

    private int width = 1280;
    private int height = 720;

    private int sensorOrientation = 270;
    private boolean bFrontCamera = true;
    private int displayRotation = Surface.ROTATION_0;

    public void initGraph() {
        pipeGraph = AoceWrapper.getPipeGraphFactory(GpuType.vulkan).createGraph();
        layerFactory = AoceWrapper.getLayerFactory(GpuType.vulkan);
        inputLayer = layerFactory.createInput();
        outputLayer = layerFactory.createOutput();
        yuv2RGBALayer = layerFactory.createYUV2RGBA();
        transposeLayerNcnn = layerFactory.createTranspose();
        transposeLayer = layerFactory.createTranspose();
        flipLayer = layerFactory.createFlip();
        orientFlipLayer = layerFactory.createFlip();
        reSizeLayer = layerFactory.createSize();

        faceDetector = AoceWrapper.createFaceDetector();
        faceKeypointDetector = AoceWrapper.createFaceKeypointDetector();
        ncnnInLayer = AoceWrapper.createNcnnInLayer();
        ncnnInCropLayer = AoceWrapper.createNcnnInCropLayer();
        drawRectLayer = AoceWrapper.createDrawRectLayer();
        drawPointsLayer = AoceWrapper.createDrawPointsLayer();

        faceDetector.setDraw(5,new vec4(0.0f,1.0f,0.0f,1.0f));
        faceKeypointDetector.setDraw(5,new vec4(1.0f,0.0f,0.0f,1.0f));

        FlipParamet fp = flipLayer.getParamet();
        fp.setBFlipX(0);
        fp.setBFlipY(1);
        flipLayer.updateParamet(fp);

        // transposeLayerNcnn/orientFlipLayer由updateOrientation根据屏幕方向设置

        TransposeParamet tp = transposeLayer.getParamet();
        tp.setBFlipX(1);
        tp.setBFlipY(0);
        transposeLayer.updateParamet(tp);

        OutputParamet op = outputLayer.getParamet();
        op.setBGpu(1);
        op.setBCpu(0);
        outputLayer.updateParamet(op);

        ReSizeParamet reSizeParamet = reSizeLayer.getParamet();
        reSizeParamet.setNewHeight(480);
        reSizeParamet.setNewWidth(480);
        reSizeLayer.updateParamet(reSizeParamet);

        initLayers();
        updateOrientation();
        loadNetAsync();
    }

    // 加载模型(包括ncnn创建vulkan pipeline)需要好几秒,放到后台线程,
    // 摄像头画面先显示,模型加载完后再开始检测并显示人脸框/关键点
    private void loadNetAsync() {
        // 默认的框是整个画面的边框,模型加载完之前设成透明(人脸检测会接管颜色)
        DrawRectParamet drawRect = drawRectLayer.getParamet();
        drawRect.setColor(new vec4(0.0f, 0.0f, 0.0f, 0.0f));
        drawRectLayer.updateParamet(drawRect);
        Thread thread = new Thread(() -> {
            loadNet();
        }, "aoce-load-net");
        thread.start();
    }

    public void openCamera(Context context) {
        openCamera(context, false);
    }

    public void openCamera(Context context, boolean bFront) {
        if (videoDevice != null && videoDevice.bOpen()) {
            videoDevice.close();
        }
        int deviceCount = AoceWrapper.getVideoManager(CameraType.and_camera2).getDeviceCount();
        for (int i = 0; i < deviceCount; i++) {
            videoDevice = AoceWrapper.getVideoManager(CameraType.and_camera2).getDevice(i);
            if (videoDevice.back() != bFront) {
                break;
            }
        }
        int formatIndex = videoDevice.findFormatIndex(width, height);
        if (formatIndex < 0) {
            formatIndex = 0;
        }
        videoDevice.setFormat(formatIndex);
        videoDevice.open();

        videoFormat = videoDevice.getSelectFormat();
        width = videoFormat.getWidth();
        height = videoFormat.getHeight();

        bFrontCamera = !videoDevice.back();
        CameraManager cameraManager = (CameraManager) context.getSystemService(Context.CAMERA_SERVICE);
        try {
            CameraCharacteristics characteristics = cameraManager.getCameraCharacteristics(videoDevice.getId());
            Integer orientation = characteristics.get(CameraCharacteristics.SENSOR_ORIENTATION);
            if (orientation != null) {
                sensorOrientation = orientation;
            }
        } catch (CameraAccessException | IllegalArgumentException e) {
            e.printStackTrace();
        }
        updateOrientation();

        videoDevice.setObserver(this);
    }

    public void closeCamera() {
        if (videoDevice != null) {
            videoDevice.close();
        }
    }

    private void loadNet(){
        faceDetector.initNet(ncnnInLayer,drawRectLayer);
        faceDetector.setFaceKeypointObserver(ncnnInCropLayer);
        faceKeypointDetector.initNet(ncnnInCropLayer,drawPointsLayer);
    }

    public void initLayers() {
        pipeGraph.clear();
        // 先旋转成与屏幕方向一致的正立画面再给ncnn,人脸模型只能检测正立的人脸
        extraLayer = pipeGraph.addNode(inputLayer).addNode(yuv2RGBALayer).addNode(transposeLayerNcnn)
                .addNode(orientFlipLayer);
        pipeGraph.addNode(ncnnInLayer);
        pipeGraph.addNode(ncnnInCropLayer);
        orientFlipLayer.getLayer().addLine(ncnnInLayer);
        orientFlipLayer.getLayer().addLine(ncnnInCropLayer.getLayer());
        // GL显示时会上下颠倒,输出前用flipLayer再翻转回来
        orientFlipLayer.getLayer().addNode(drawRectLayer).addNode(drawPointsLayer)
                .addNode(flipLayer).addNode(outputLayer);
    }

    // rotation: Display.getRotation()的值(Surface.ROTATION_0...)
    public void setDisplayRotation(int rotation) {
        displayRotation = rotation;
        updateOrientation();
    }

    // 顺时针旋转矩阵(y轴向下的中心坐标),行主序{m00,m01,m10,m11}
    private static int[] rotateCW(int degrees) {
        switch (((degrees % 360) + 360) % 360 / 90) {
            case 1: return new int[]{0, -1, 1, 0};
            case 2: return new int[]{-1, 0, 0, -1};
            case 3: return new int[]{0, 1, -1, 0};
            default: return new int[]{1, 0, 0, 1};
        }
    }

    private static int[] mul(int[] a, int[] b) {
        return new int[]{a[0] * b[0] + a[1] * b[2], a[0] * b[1] + a[1] * b[3],
                a[2] * b[0] + a[3] * b[2], a[2] * b[1] + a[3] * b[3]};
    }

    // 计算输出画面坐标到摄像头原始画面坐标的变换M,再用转置(M非对角)或翻转(M对角)实现.
    // M = 摄像头方向的逆旋转 * 前置镜像 * 屏幕旋转
    private void updateOrientation() {
        if (transposeLayerNcnn == null) {
            return;
        }
        int[] m = rotateCW(-sensorOrientation);
        if (bFrontCamera) {
            m = mul(m, new int[]{-1, 0, 0, 1});
        }
        m = mul(m, rotateCW(displayRotation * 90));
        boolean bTranspose = m[0] == 0;
        TransposeParamet tp = transposeLayerNcnn.getParamet();
        FlipParamet fp = orientFlipLayer.getParamet();
        if (bTranspose) {
            // 转置: out(u,v) = in(flipY ? -v : v, flipX ? -u : u)
            tp.setBFlipX(m[2] < 0 ? 1 : 0);
            tp.setBFlipY(m[1] < 0 ? 1 : 0);
            fp.setBFlipX(0);
            fp.setBFlipY(0);
        } else {
            tp.setBFlipX(0);
            tp.setBFlipY(0);
            fp.setBFlipX(m[0] < 0 ? 1 : 0);
            fp.setBFlipY(m[3] < 0 ? 1 : 0);
        }
        transposeLayerNcnn.updateParamet(tp);
        orientFlipLayer.updateParamet(fp);
        transposeLayerNcnn.getLayer().setVisable(bTranspose);
        orientFlipLayer.getLayer().setVisable(fp.getBFlipX() != 0 || fp.getBFlipY() != 0);
    }

    public void clearLayers() {
        pipeGraph.clear();
    }

    @Override
    public void onVideoFrame(VideoFrame frame) {
        if (AoceWrapper.getYuvIndex(frame.getVideoType()) < 0) {
            yuv2RGBALayer.getLayer().setVisable(false);
        } else if (videoFormat != null) {
            if (yuv2RGBALayer.getParamet().getType() != frame.getVideoType()) {
                yuv2RGBALayer.getLayer().setVisable(true);
                YUVParamet yp = yuv2RGBALayer.getParamet();
                yp.setType(frame.getVideoType());
                yuv2RGBALayer.updateParamet(yp);
            }
        }
        inputLayer.inputCpuData(frame);
        pipeGraph.run();
    }

    public void showGL(int textureId, int width, int height) {
        gpuTex.setImage(textureId);
        gpuTex.setWidth(width);
        gpuTex.setHeight(height);
        outputLayer.outGLGpuTex(gpuTex);
    }
}
