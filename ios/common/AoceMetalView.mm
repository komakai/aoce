#import "AoceMetalView.h"

static NSString* const kShaderSource = @R"(
#include <metal_stdlib>
using namespace metal;

struct VertexOut {
    float4 position [[position]];
    float2 uv;
};

vertex VertexOut aoceVertex(uint vid [[vertex_id]], constant float2& scale [[buffer(0)]]) {
    float2 pos = float2((vid & 1) ? 1.0 : -1.0, (vid & 2) ? -1.0 : 1.0);
    VertexOut out;
    out.position = float4(pos * scale, 0.0, 1.0);
    out.uv = float2((vid & 1) ? 1.0 : 0.0, (vid & 2) ? 1.0 : 0.0);
    return out;
}

fragment float4 aoceFragment(VertexOut in [[stage_in]], texture2d<float> tex [[texture(0)]]) {
    constexpr sampler s(filter::linear, address::clamp_to_edge);
    return float4(tex.sample(s, in.uv).rgb, 1.0);
}
)";

@interface AoceMetalView () <MTKViewDelegate>
@property(nonatomic, strong) id<MTLCommandQueue> commandQueue;
@property(nonatomic, strong) id<MTLRenderPipelineState> pipeline;
@property(nonatomic, strong) id<MTLTexture> texture;
@end

@implementation AoceMetalView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame device:MTLCreateSystemDefaultDevice()];
    if (self) {
        self.colorPixelFormat = MTLPixelFormatBGRA8Unorm;
        self.clearColor = MTLClearColorMake(0, 0, 0, 1);
        self.preferredFramesPerSecond = 30;
        self.delegate = self;
        [self setupPipeline];
    }
    return self;
}

- (void)setupPipeline {
    NSError* error = nil;
    id<MTLLibrary> library = [self.device newLibraryWithSource:kShaderSource
                                                       options:nil
                                                         error:&error];
    if (!library) {
        NSLog(@"aoce metal view shader error: %@", error);
        return;
    }
    MTLRenderPipelineDescriptor* desc = [[MTLRenderPipelineDescriptor alloc] init];
    desc.vertexFunction = [library newFunctionWithName:@"aoceVertex"];
    desc.fragmentFunction = [library newFunctionWithName:@"aoceFragment"];
    desc.colorAttachments[0].pixelFormat = self.colorPixelFormat;
    self.pipeline = [self.device newRenderPipelineStateWithDescriptor:desc error:&error];
    if (!self.pipeline) {
        NSLog(@"aoce metal view pipeline error: %@", error);
    }
    self.commandQueue = [self.device newCommandQueue];
}

- (void)updateTexture {
    if (self.outputLayer == nullptr) {
        self.texture = nil;
        return;
    }
    aoce::MetalOutGpuTex outTex = {};
    if (self.outputLayer->outMetalGpuTex(outTex) && outTex.texture) {
        // 持有一份引用,输出层重建资源时不会影响正在绘制的纹理
        self.texture = (__bridge id<MTLTexture>)outTex.texture;
    }
}

- (void)drawInMTKView:(MTKView*)view {
    [self updateTexture];
    MTLRenderPassDescriptor* pass = view.currentRenderPassDescriptor;
    id<CAMetalDrawable> drawable = view.currentDrawable;
    if (!pass || !drawable || !self.pipeline) {
        return;
    }
    id<MTLCommandBuffer> commandBuffer = [self.commandQueue commandBuffer];
    id<MTLRenderCommandEncoder> encoder =
        [commandBuffer renderCommandEncoderWithDescriptor:pass];
    id<MTLTexture> texture = self.texture;
    if (texture) {
        CGSize size = view.drawableSize;
        float viewAspect = size.width / MAX(size.height, 1.0);
        float texAspect = (float)texture.width / MAX(texture.height, 1);
        simd_float2 scale = {1.0f, 1.0f};
        if (texAspect > viewAspect) {
            scale.y = viewAspect / texAspect;
        } else {
            scale.x = texAspect / viewAspect;
        }
        [encoder setRenderPipelineState:self.pipeline];
        [encoder setVertexBytes:&scale length:sizeof(scale) atIndex:0];
        [encoder setFragmentTexture:texture atIndex:0];
        [encoder drawPrimitives:MTLPrimitiveTypeTriangleStrip vertexStart:0 vertexCount:4];
    }
    [encoder endEncoding];
    [commandBuffer presentDrawable:drawable];
    [commandBuffer commit];
}

- (void)mtkView:(MTKView*)view drawableSizeWillChange:(CGSize)size {
}

- (UIImage*)snapshot {
    id<MTLTexture> texture = self.texture;
    if (!texture) {
        return nil;
    }
    NSUInteger width = texture.width;
    NSUInteger height = texture.height;
    // 输出纹理是GPU私有内存,先blit到共享内存的纹理再读回
    MTLTextureDescriptor* desc =
        [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatRGBA8Unorm
                                                           width:width
                                                          height:height
                                                       mipmapped:NO];
    desc.storageMode = MTLStorageModeShared;
    id<MTLTexture> readTex = [self.device newTextureWithDescriptor:desc];
    id<MTLCommandBuffer> commandBuffer = [self.commandQueue commandBuffer];
    id<MTLBlitCommandEncoder> blit = [commandBuffer blitCommandEncoder];
    [blit copyFromTexture:texture toTexture:readTex];
    [blit endEncoding];
    [commandBuffer commit];
    [commandBuffer waitUntilCompleted];

    NSMutableData* data = [NSMutableData dataWithLength:width * height * 4];
    [readTex getBytes:data.mutableBytes
          bytesPerRow:width * 4
           fromRegion:MTLRegionMake2D(0, 0, width, height)
          mipmapLevel:0];
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
    CGImageRef cgImage =
        CGImageCreate(width, height, 8, 32, width * 4, colorSpace,
                      kCGImageAlphaNoneSkipLast | kCGBitmapByteOrder32Big, provider, nullptr,
                      false, kCGRenderingIntentDefault);
    UIImage* image = [UIImage imageWithCGImage:cgImage];
    CGImageRelease(cgImage);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);
    return image;
}

@end
