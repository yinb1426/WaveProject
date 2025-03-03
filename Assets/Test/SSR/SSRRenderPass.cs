using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

[Serializable]
public class SSRRenderPassSetting
{
    public RenderPassEvent renderPassEvent;
    public Material material;
}

public class SSRRenderPass : ScriptableRenderPass
{
    private readonly SSRRenderPassSetting setting;

    private RenderTexture positionTexture;

    public SSRRenderPass(SSRRenderPassSetting setting)
    {
        this.setting = setting;
    }

    public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
    {
        renderPassEvent = setting.renderPassEvent;

        CreateTexture(renderingData);

        CommandBuffer commandBuffer = CommandBufferPool.Get("SSR");

        commandBuffer.Blit(null, renderingData.cameraData.renderer.cameraColorTarget, setting.material);

        context.ExecuteCommandBuffer(commandBuffer);
        CommandBufferPool.Release(commandBuffer);

    }

    private void CreateTexture(RenderingData renderingData)
    {
        // ��ȡ��Ļ�Ŀ��
        int width = renderingData.cameraData.camera.pixelWidth;
        int height = renderingData.cameraData.camera.pixelHeight;
        if (positionTexture != null && positionTexture.width == width && positionTexture.height == height)
            return;

        // ������ȫ���ͷ�
        ReleaseTexture();

        // �����µ���ʱ����
        RenderTextureDescriptor textureDescriptor = new RenderTextureDescriptor(width, height, RenderTextureFormat.ARGBFloat, 0);
        positionTexture = RenderTexture.GetTemporary(textureDescriptor);
        positionTexture.filterMode = FilterMode.Point;
    }

    private void ReleaseTexture()
    {
        if (positionTexture != null)
        {
            RenderTexture.ReleaseTemporary(positionTexture);
            positionTexture = null;
        }
    }

}