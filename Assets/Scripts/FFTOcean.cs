using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using static UnityEditor.Rendering.CameraUI;
using UnityEngine.Windows;

public class FFTOcean : MonoBehaviour
{
    public ComputeShader _FFTOceanComputeShader;

    // Params
    public int _TextureResolutionPower = 10;
    public float _A = 10.0f;
    public float _Lambda = -1f;
    public float _HeightScale = 1f;
    public float _WindScale = 2f;
    public float _TimeScale = 1f;
    public float _OceanWidth = 100f;
    public Vector4 _WindAndSeed = new Vector4(0.1f, 0.2f, 0f, 0f);

    public Material _OceanMaterial;

    // Kernels
    private int kernelComputeGaussianRandom;
    private int kernelCreateHeightSpectrum;
    private int kernelCreateDisplaceSpectrum;
    private int kernelFFTHorizontal;
    private int kernelFFTHorizontalEnd;
    private int kernelFFTVertical;
    private int kernelFFTVerticalEnd;
    private int kernelCalculateDisplacement;
    private int kernelCalculateNormal;

    // Textures
    private RenderTexture gaussianRandomTexture;
    private RenderTexture heightSpectrumTexture;
    private RenderTexture displaceXSpectrumTexture;
    private RenderTexture displaceZSpectrumTexture;
    private RenderTexture outputSpectrumTexture;
    private RenderTexture displacementTexture;
    private RenderTexture normalTexture;

    private int groupX;
    private int groupY;
    private int textureResolution;
    private float currentTime = 0;

    // Start is called before the first frame update
    void Start()
    {
        textureResolution = (int)Math.Pow(2, _TextureResolutionPower);
        groupX = Mathf.CeilToInt(textureResolution / 16f);
        groupY = Mathf.CeilToInt(textureResolution / 16f);

        // Create textures
        gaussianRandomTexture = CreateRenderTexture(textureResolution);
        heightSpectrumTexture = CreateRenderTexture(textureResolution);
        displaceXSpectrumTexture = CreateRenderTexture(textureResolution);
        displaceZSpectrumTexture = CreateRenderTexture(textureResolution);
        outputSpectrumTexture = CreateRenderTexture(textureResolution);
        displacementTexture = CreateRenderTexture(textureResolution);
        normalTexture = CreateRenderTexture(textureResolution);

        // Find kernels
        kernelComputeGaussianRandom = _FFTOceanComputeShader.FindKernel("ComputeGaussianRandom");
        kernelCreateHeightSpectrum = _FFTOceanComputeShader.FindKernel("CreateHeightSpectrum");
        kernelCreateDisplaceSpectrum = _FFTOceanComputeShader.FindKernel("CreateDisplaceSpectrum");
        kernelFFTHorizontal = _FFTOceanComputeShader.FindKernel("FFTHorizontal");
        kernelFFTHorizontalEnd = _FFTOceanComputeShader.FindKernel("FFTHorizontalEnd");
        kernelFFTVertical = _FFTOceanComputeShader.FindKernel("FFTVertical");
        kernelFFTVerticalEnd = _FFTOceanComputeShader.FindKernel("FFTVerticalEnd");
        kernelCalculateDisplacement = _FFTOceanComputeShader.FindKernel("CalculateDisplacement");
        kernelCalculateNormal = _FFTOceanComputeShader.FindKernel("CalculateNormal");

        // Generate Gaussian Random Texture
        _FFTOceanComputeShader.SetTexture(kernelComputeGaussianRandom, "gaussianRandomTexture", gaussianRandomTexture);
        _FFTOceanComputeShader.Dispatch(kernelComputeGaussianRandom, groupX, groupY, 1);
    }

    // Update is called once per frame
    void Update()
    {
        // Update Time
        currentTime += Time.deltaTime * _TimeScale;

        // Update Wind And Seed
        _WindAndSeed.z = UnityEngine.Random.Range(1f, 10f);
        _WindAndSeed.w = UnityEngine.Random.Range(1f, 10f);
        Vector2 wind = new Vector2(_WindAndSeed.x, _WindAndSeed.y);
        wind.Normalize();
        wind *= _WindScale;

        // Shader Set Params
        _FFTOceanComputeShader.SetInt("resolution", textureResolution);
        _FFTOceanComputeShader.SetFloat("A", _A);
        _FFTOceanComputeShader.SetVector("windAndSeed", new Vector4(wind.x, wind.y, _WindAndSeed.z, _WindAndSeed.w));
        _FFTOceanComputeShader.SetFloat("currentTime", currentTime);
        _FFTOceanComputeShader.SetFloat("lambda", _Lambda);
        _FFTOceanComputeShader.SetFloat("heightScale", _HeightScale);
        _FFTOceanComputeShader.SetFloat("oceanWidth", _OceanWidth);

        // Generate Height Spectrum
        _FFTOceanComputeShader.SetTexture(kernelCreateHeightSpectrum, "gaussianRandomTexture", gaussianRandomTexture);
        _FFTOceanComputeShader.SetTexture(kernelCreateHeightSpectrum, "heightSpectrumTexture", heightSpectrumTexture);
        _FFTOceanComputeShader.Dispatch(kernelCreateHeightSpectrum, groupX, groupY, 1);

        // Generate Displace Spectrum
        _FFTOceanComputeShader.SetTexture(kernelCreateDisplaceSpectrum, "heightSpectrumTexture", heightSpectrumTexture);
        _FFTOceanComputeShader.SetTexture(kernelCreateDisplaceSpectrum, "displaceXSpectrumTexture", displaceXSpectrumTexture);
        _FFTOceanComputeShader.SetTexture(kernelCreateDisplaceSpectrum, "displaceZSpectrumTexture", displaceZSpectrumTexture);
        _FFTOceanComputeShader.Dispatch(kernelCreateDisplaceSpectrum, groupX, groupY, 1);

        // FFT
        // Horizontal FFT
        for (int i = 0; i < _TextureResolutionPower; i++)
        {
            int ns = (int)Mathf.Pow(2, i);
            _FFTOceanComputeShader.SetInt("ns", ns);
            if (i != _TextureResolutionPower - 1)
            {
                ComputeFFT(kernelFFTHorizontal, ref heightSpectrumTexture);
                ComputeFFT(kernelFFTHorizontal, ref displaceXSpectrumTexture);
                ComputeFFT(kernelFFTHorizontal, ref displaceZSpectrumTexture);
            }
            else
            {
                ComputeFFT(kernelFFTHorizontalEnd, ref heightSpectrumTexture);
                ComputeFFT(kernelFFTHorizontalEnd, ref displaceXSpectrumTexture);
                ComputeFFT(kernelFFTHorizontalEnd, ref displaceZSpectrumTexture);
            }
        }

        // Vertical FFT
        for (int i = 0; i < _TextureResolutionPower; i++)
        {
            int ns = (int)Mathf.Pow(2, i);
            _FFTOceanComputeShader.SetInt("ns", ns);
            if (i != _TextureResolutionPower - 1)
            {
                ComputeFFT(kernelFFTVertical, ref heightSpectrumTexture);
                ComputeFFT(kernelFFTVertical, ref displaceXSpectrumTexture);
                ComputeFFT(kernelFFTVertical, ref displaceZSpectrumTexture);
            }
            else
            {
                ComputeFFT(kernelFFTVerticalEnd, ref heightSpectrumTexture);
                ComputeFFT(kernelFFTVerticalEnd, ref displaceXSpectrumTexture);
                ComputeFFT(kernelFFTVerticalEnd, ref displaceZSpectrumTexture);
            }
        }

        // Calculate Displacement
        _FFTOceanComputeShader.SetTexture(kernelCalculateDisplacement, "heightSpectrumTexture", heightSpectrumTexture);
        _FFTOceanComputeShader.SetTexture(kernelCalculateDisplacement, "displaceXSpectrumTexture", displaceXSpectrumTexture);
        _FFTOceanComputeShader.SetTexture(kernelCalculateDisplacement, "displaceZSpectrumTexture", displaceZSpectrumTexture);
        _FFTOceanComputeShader.SetTexture(kernelCalculateDisplacement, "displacementTexture", displacementTexture);
        _FFTOceanComputeShader.Dispatch(kernelCalculateDisplacement, groupX, groupY, 1);

        // Calculate Normal
        _FFTOceanComputeShader.SetTexture(kernelCalculateNormal, "displacementTexture", displacementTexture);
        _FFTOceanComputeShader.SetTexture(kernelCalculateNormal, "normalTexture", normalTexture);
        _FFTOceanComputeShader.Dispatch(kernelCalculateNormal, groupX, groupY, 1);

        // Set Material Texture                                                                    
        _OceanMaterial.SetTexture("_DisplacementMap", displacementTexture);
        _OceanMaterial.SetTexture("_NormalMap", normalTexture);
    }

    void OnDestroy()
    {
        if(gaussianRandomTexture != null)
        {
            gaussianRandomTexture.Release();
            Destroy(gaussianRandomTexture);
            gaussianRandomTexture = null;

            heightSpectrumTexture.Release();
            Destroy(heightSpectrumTexture);
            heightSpectrumTexture = null;

            displaceXSpectrumTexture.Release();
            Destroy(displaceXSpectrumTexture);
            displaceXSpectrumTexture = null;

            displaceZSpectrumTexture.Release();
            Destroy(displaceZSpectrumTexture);
            displaceZSpectrumTexture = null;

            outputSpectrumTexture.Release();
            Destroy(outputSpectrumTexture);
            outputSpectrumTexture = null;

            displacementTexture.Release();
            Destroy(displacementTexture);
            displacementTexture = null;

            normalTexture.Release();
            Destroy(normalTexture);
            normalTexture = null;
        }
    }

    private void ComputeFFT(int kernel, ref RenderTexture inputSpectrumTexture)
    {
        _FFTOceanComputeShader.SetTexture(kernel, "inputSpectrumTexture", inputSpectrumTexture);
        _FFTOceanComputeShader.SetTexture(kernel, "outputSpectrumTexture", outputSpectrumTexture);
        _FFTOceanComputeShader.Dispatch(kernel, groupX, groupY, 1);

        // 交换输入输出纹理
        RenderTexture rt = inputSpectrumTexture;
        inputSpectrumTexture = outputSpectrumTexture;
        outputSpectrumTexture = rt;
        // (outputSpectrumTexture, inputSpectrumTexture) = (inputSpectrumTexture, outputSpectrumTexture);
    }
    private RenderTexture CreateRenderTexture(int resolution)
    {
        RenderTexture texture = new RenderTexture(resolution, resolution, 0, RenderTextureFormat.ARGBFloat);
        texture.enableRandomWrite = true;
        return texture;
    }
}
