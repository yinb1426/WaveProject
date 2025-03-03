using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering.Universal;

public class SSRRendererFeature : ScriptableRendererFeature
{
    public SSRRenderPassSetting setting;
    public SSRRenderPass pass;

    public override void Create()
    {
        if (pass == null)
            pass = new SSRRenderPass(setting);
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        if (renderingData.cameraData.camera.name != "Main Camera")
            return;
        renderer.EnqueuePass(pass);
    }
}
