# 编译iOS(MoltenVK)使用的shader: ios/source -> ios/target
# 与上级目录的shader相比,storage image加了readonly/writeonly等修改,原因见ios/README.md
import os
import subprocess
import sys

path = os.path.dirname(os.path.realpath(__file__))
failed = []
count = 0
with open(os.path.join(path, "glslindex.txt")) as lines:
    for line in lines:
        nodes = line.split()
        if not nodes:
            continue
        dst = (nodes[1] if len(nodes) > 1 else nodes[0]) + ".spv"
        macros = " ".join("-D" + m for m in nodes[2:])
        cmd = "glslangValidator -V %s -o %s %s" % (
            os.path.join(path, "source", nodes[0]), os.path.join(path, "target", dst), macros)
        count += 1
        if subprocess.call(cmd, shell=True, stdout=subprocess.DEVNULL) != 0:
            failed.append(dst)
if failed:
    print("ERROR: failed to compile " + ", ".join(failed))
    sys.exit(1)
print("SUCCESS: All %i shaders compiled to SPIR-V" % count)
