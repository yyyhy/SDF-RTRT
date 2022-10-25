using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;
public class GRB2Gray : MonoBehaviour
{
    public ComputeShader shader;
    public Texture2D tex;
    private int id;
    public RawImage image;
    public float[] RGBWeight;
    public float[] tmp;
    RenderTexture texture;
    // Start is called before the first frame update
    void Start()
    {
        tmp=new float[RGBWeight.Length];
        for(int i=0;i<RGBWeight.Length;i++)
            tmp[i]=RGBWeight[i];
        texture=new RenderTexture(tex.width,tex.height,16);
        texture.enableRandomWrite=true;
        texture.Create();
        image.texture=texture;     
        image.rectTransform.SetSizeWithCurrentAnchors(RectTransform.Axis.Horizontal, texture.width/2);
        image.rectTransform.SetSizeWithCurrentAnchors(RectTransform.Axis.Vertical, texture.height/2);
        id=shader.FindKernel("CSMain");
        shader.SetTexture(id,"Result",texture);
        shader.SetTexture(id,"src",tex);
        shader.SetFloat("r",RGBWeight[0]);
        shader.SetFloat("g",RGBWeight[1]);
        shader.SetFloat("b",RGBWeight[2]);
        shader.Dispatch(id,tex.width/8,tex.height/8,100);
    }

    // Update is called once per frame
    void Update()
    {
        bool change=false;
        for(int i=0;i<tmp.Length;i++){
            if(tmp[i]!=RGBWeight[i]){
                tmp[i]=RGBWeight[i];
                change=true;
                if(i==0)
                    shader.SetFloat("r",tmp[i]);
                if(i==1)
                    shader.SetFloat("g",tmp[i]);
                if(i==2)
                    shader.SetFloat("b",tmp[i]);
            }
        }
        if(change)
            shader.Dispatch(id,tex.width/8,tex.height/8,100);
    }
}
