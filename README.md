# Wave Project
## 已实现功能
* Gerstner Wave: 使用3组波浪参数实现简单的波浪效果
* Gerstner Wave2: 使用Compute shader计算位移和法线贴图，可以使用N组波浪参数
* FFT Wave
* 波浪面模型的曲面细分
## 注意事项
* Gerstner Wave Shader/Material为在顶点着色器中实现波浪效果的着色器和材质
* Gerstner Wave Shader/Material2为使用计算着色器计算Gerstner Wave，得到位移和法线贴图，再实现波浪效果的着色器。
> 需要配合GerstnerOcean.cs脚本和GerstnerOceanComputeShader.compute使用方能实现效果。
* FFTOceanShader/Material为使用计算着色器计算FFT Wave，得到位移和法线贴图，再实现波浪效果的着色器。
> 需要配合FFTOcean.cs脚本和FFTOceanComputeShader.compute使用方能实现效果。
* 其他为声明的代码/脚本，为测试所用文件，可以忽略/删除