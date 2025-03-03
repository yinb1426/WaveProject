using System;
using System.Collections;
using System.Collections.Generic;
using Unity.Mathematics;
using UnityEngine;

public class GerstnerOcean : MonoBehaviour
{
    [Header("Waves: Directions(dx, dy), Steepness, WaveLength")]
    public Vector4[] _Waves;

    public int _TextureResolutionPower = 10;
    public float _OceanWidth = 100.0f;
    public float _TimeScale = 1.5f;

    public ComputeShader _GerstnerComputeShader;
    public Material _GerstnerMaterial;

    private RenderTexture displacementTexture;
    private RenderTexture normalTexture;
    private RenderTexture bubblesTexture;

    private int groupX;
    private int groupY;
    private int textureResolution;
    private float currentTime = 0;

    private int kernelComputeGerstnerWave;
    private int kernelComputeBubbles;
    private ComputeBuffer gerstnerWavesBuffer;

    // Start is called before the first frame update
    void Start()
    {
        textureResolution = (int)Math.Pow(2, _TextureResolutionPower);
        groupX = Mathf.CeilToInt(textureResolution / 16f);
        groupY = Mathf.CeilToInt(textureResolution / 16f);

        if (displacementTexture != null && displacementTexture.IsCreated())
        {
            DestroyAllTextures();
        }

        displacementTexture = CreateRenderTexture(textureResolution);
        normalTexture = CreateRenderTexture(textureResolution);
        bubblesTexture = CreateRenderTexture(textureResolution);

        gerstnerWavesBuffer = new ComputeBuffer(_Waves.Length, sizeof(float) * 4);
        gerstnerWavesBuffer.SetData(_Waves);

        // Find kernels
        kernelComputeGerstnerWave = _GerstnerComputeShader.FindKernel("ComputeGerstnerWave");
        kernelComputeBubbles = _GerstnerComputeShader.FindKernel("ComputeBubbles");
        _GerstnerComputeShader.SetInt("resolution", textureResolution);
    }

    // Update is called once per frame
    void Update()
    {
        currentTime += Time.deltaTime * _TimeScale;

        // Compute Gerstner Wave
        _GerstnerComputeShader.SetFloat("oceanWidth", _OceanWidth);
        _GerstnerComputeShader.SetFloat("currentTime", currentTime);
        _GerstnerComputeShader.SetBuffer(kernelComputeGerstnerWave, "waves", gerstnerWavesBuffer);
        _GerstnerComputeShader.SetTexture(kernelComputeGerstnerWave, "displacementTexture", displacementTexture);
        //_GerstnerComputeShader.SetTexture(kernelComputeGerstnerWave, "normalTexture", normalTexture);
        _GerstnerComputeShader.Dispatch(kernelComputeGerstnerWave, groupX, groupY, 1);

        // Compute Bubbles
        _GerstnerComputeShader.SetTexture(kernelComputeBubbles, "displacementTexture", displacementTexture);
        _GerstnerComputeShader.SetTexture(kernelComputeBubbles, "normalTexture", normalTexture);
        _GerstnerComputeShader.SetTexture(kernelComputeBubbles, "bubblesTexture", bubblesTexture);
        _GerstnerComputeShader.Dispatch(kernelComputeBubbles, groupX, groupY, 1);

        _GerstnerMaterial.SetTexture("_DisplacementMap", displacementTexture);
        _GerstnerMaterial.SetTexture("_NormalMap", normalTexture);
        _GerstnerMaterial.SetTexture("_BubblesTexture", bubblesTexture);
    }

    private RenderTexture CreateRenderTexture(int resolution)
    {
        RenderTexture texture = new RenderTexture(resolution, resolution, 0, RenderTextureFormat.ARGBFloat);
        texture.enableRandomWrite = true;
        return texture;
    }

    private void DestroyAllTextures()
    {
        displacementTexture.Release();
        Destroy(displacementTexture);
        displacementTexture = null;

        normalTexture.Release();
        Destroy(normalTexture);
        normalTexture = null;

        bubblesTexture.Release();
        Destroy(bubblesTexture);
        bubblesTexture = null;
    }
}
