using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

[ExecuteInEditMode]
public class scan : ScriptableRendererFeature

{
    
    [System.Serializable]
    public class setting

    {
        
        public Material mat;

        public RenderPassEvent Event = RenderPassEvent.AfterRenderingTransparents;

    }

    public setting mysetting = new setting();

    class CustomRenderPass : ScriptableRenderPass

    {

        public Material mat;

        RenderTargetIdentifier sour;
        
        public void set(RenderTargetIdentifier sour)

        {

            this.sour = sour;

        }

        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)

        {

            int temp = Shader.PropertyToID("temp");

            CommandBuffer cmd = CommandBufferPool.Get("Newscan");

            RenderTextureDescriptor desc = renderingData.cameraData.cameraTargetDescriptor;

            Camera cam = renderingData.cameraData.camera;

            float height = cam.nearClipPlane * Mathf.Tan(Mathf.Deg2Rad * cam.fieldOfView * 0.5f);

            Vector3 up = cam.transform.up * height;

            Vector3 right = cam.transform.right * height * cam.aspect;

            Vector3 forward = cam.transform.forward * cam.nearClipPlane;

            Vector3 ButtomLeft = forward - right - up;

            float scale = ButtomLeft.magnitude / cam.nearClipPlane;

            ButtomLeft.Normalize();

            ButtomLeft *= scale;

            Vector3 ButtomRight = forward + right - up;

            ButtomRight.Normalize();

            ButtomRight *= scale;

            Vector3 TopRight = forward + right + up;

            TopRight.Normalize();

            TopRight *= scale;

            Vector3 TopLeft = forward - right + up;

            TopLeft.Normalize();

            TopLeft *= scale;

            Matrix4x4 MATRIX = new Matrix4x4();

            MATRIX.SetRow(0, ButtomLeft);

            MATRIX.SetRow(1, ButtomRight);

            MATRIX.SetRow(2, TopRight);

            MATRIX.SetRow(3, TopLeft);
            //Debug.Log(mat == null);
            mat.SetMatrix("Matrix", MATRIX);

            cmd.GetTemporaryRT(temp, desc);

            cmd.Blit(sour, temp, mat);

            cmd.Blit(temp, sour);

            context.ExecuteCommandBuffer(cmd);

            cmd.ReleaseTemporaryRT(temp);

            CommandBufferPool.Release(cmd);

        }

    }

    CustomRenderPass m_ScriptablePass;

    public override void Create()

    {

        m_ScriptablePass = new CustomRenderPass();

        m_ScriptablePass.mat = mysetting.mat;

        m_ScriptablePass.renderPassEvent = mysetting.Event;

    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)

    {

        m_ScriptablePass.set(renderer.cameraColorTarget);

        renderer.EnqueuePass(m_ScriptablePass);

    }

}
