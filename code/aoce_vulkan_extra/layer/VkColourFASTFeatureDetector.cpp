#include "VkColourFASTFeatureDetector.hpp"

#include "aoce/layer/PipeGraph.hpp"


namespace aoce {
namespace vulkan {
namespace layer {

VkColourFASTFeatureDetector::VkColourFASTFeatureDetector(/* args */) {
    glslPath = "glsl/fastFeatureDetector.comp.spv";
    setUBOSize(sizeof(float));
    updateUBO(&paramet.offset);
    inCount = 2;

    boxBlur = std::make_unique<VkBoxBlurSLayer>();
    boxBlur->updateParamet({paramet.boxSize, paramet.boxSize});
}

VkColourFASTFeatureDetector::~VkColourFASTFeatureDetector() {}

bool VkColourFASTFeatureDetector::getSampled(int inIndex) {
    // shader里二个输入都是sampler2D,descriptor类型需要一致(Metal argument buffer会校验)
    return inIndex == 0 || inIndex == 1;
}

void VkColourFASTFeatureDetector::onUpdateParamet() {
    if (paramet.offset != oldParamet.offset) {
        updateUBO(&paramet.offset);
        bParametChange = true;
    }
    if (paramet.boxSize != oldParamet.boxSize) {
        boxBlur->updateParamet({paramet.boxSize, paramet.boxSize});
    }
}

void VkColourFASTFeatureDetector::onInitGraph() {
    VkLayer::onInitGraph();
    pipeGraph->addNode(boxBlur->getLayer());
}
void VkColourFASTFeatureDetector::onInitNode() {
    boxBlur->addLine(this, 0, 1);
    setStartNode(this, 0, 0);
    setStartNode(boxBlur.get(), 0, 0);
}

}  // namespace layer
}  // namespace vulkan
}  // namespace aoce
