# ScannerShader
Unity ScannerShader for edge scanning effect on AR RealityPlane

原文在：shader taken from https://blog.csdn.net/qq_26722425/article/details/77341284


Shader 可用在：
1- EasyAR RealityPlane
2- MorphoMR RealityPlane
3- 普通Texture2d图片

功能介绍：
Shader 先在规定的图片上实行边缘提取然后再边缘上加色，接着把规定的 MaskTexture 提出扫描效果

可改因素：
边缘颜色，效果背景颜色，方向机速度，边缘重量，扫描效果

Inspector 界面简单解释：
1- Texture: 如果绑在 RealityPlane 上，Texture 在运行中默认为相机播的视频，Shader代码会根据这张图片实行边缘提取
2- MaskTex: 默认是 None，必须绑上一个图片 （Texture2D或Default都行），Shader会由这张图片实行边缘上加颜色的效果。图片里的部分越黑，效果就越明显（如果是一整片白图就没有效果，若果一整片黑就整图的效果）
3- Edge Only: 边缘提取的重量因素（MorphoMR最佳在1.0之1.5）
4- Edgge Color: 边缘加色的颜色选择
5- Background Color: 边缘加色效果上的背景颜色（目前 alpha = 0)
6- Thickness: 颜色的厚度因素 （MorphoMR最佳在0.02之0.2)
7- Speed factor: 上下扫描效果的方向和速度调整因素


互补代码或场景等等：
1- ARBehvaiourController (人鱼应用）：实现的功能使用改变 MaskTex的图片，让当没有识别图被识别的情况下，边缘加色效果仍然在运行，当识别开始模型出现时，边缘加色效果停止
（本来研究使用改变整套Shader把边缘效果换掉，需要的时候还回来，但是 Bug 在于还回来的时候边缘加色效果不重新运行，只有在一开时使用时能够运行）
把 m_MaskTextureOff 邦着一片空白的图片
把 m_MaskTextureOff 绑着规定的遮罩图片
2- Canvas_Mask_ScanFrame
创造了新的一项 Canvas 加上 Frame 的效果
启发点：
i） 能够提示用户应该把识别图准确的在框里扫描
ii）能够在周围部分加上文字提示等

得在shader的最后一部分加上下面的代码，取代之前的 return 数据，让边缘加色效果限定与一个矩形


代码研究/解释：
总结：边缘检测Shader + UV移动 + 渐变图遮罩 + 双Pass + EasyAR

1- 边缘提取用了 Sobel Operator 把每个像素（pixel)周围 8 个像素做个算数再加上规定的颜色

2- UV移动 （调查中）

3- 渐变图遮罩：把背景颜色，加上颜色的边缘，规定的 MaskTex 和 相机在 RealityPlane上实行的MainTex 融合在一起

4- 双Pass：用了两个 Shader Pass 代码 (调差中）
