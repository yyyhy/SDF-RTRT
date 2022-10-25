using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System;
using UnityEngine.UI;
public class Split : MonoBehaviour
{
    // Start is called before the first frame update
    public ComputeShader shader;
    public ComputeShader s;
    public ComputeBuffer ms;
    public ComputeBuffer fits;
    public RenderTexture texture;
    public Texture2D tex;
    public RawImage image;
    public int l=4;
    int[] m;
    float[] f;
    int id;
    int id2;
    void Start()
    {
        

        m=new int[l];
        f=new float[l];
        for(int i=0;i<l;i++){
            f[i]=-1;
            m[i]=UnityEngine.Random.Range(8,200);
        }
        //m[0]=127;
        texture=new RenderTexture(tex.width,tex.height,16);
        texture.enableRandomWrite=true;
        texture.Create();
        image.texture=texture;     
        image.rectTransform.SetSizeWithCurrentAnchors(RectTransform.Axis.Horizontal, 506);
        image.rectTransform.SetSizeWithCurrentAnchors(RectTransform.Axis.Vertical, 321);
        id=shader.FindKernel("CSMain");
        id2=s.FindKernel("CSMain");
        ms=new ComputeBuffer(m.Length,sizeof(int));
        fits=new ComputeBuffer(f.Length,sizeof(float));
        ms.SetData(m);
        fits.SetData(f);
        shader.SetTexture(id,"src",tex);
        s.SetTexture(id2,"src",tex);
        s.SetTexture(id2,"Result",texture);
        shader.SetBuffer(id,"ms",ms);
        shader.SetBuffer(id,"fit",fits);
        shader.SetInt("w",texture.width);
        shader.SetInt("h",texture.height);
        print_m();
    }
    void run(){
        ms.SetData(m);
        shader.SetBuffer(id,"ms",ms);
        shader.Dispatch(id,l/4,l/4*2,5);
    }
    void print_fit(){
        fits.GetData(f);
        string v="";
        for(int i=0;i<l;i++)
            v+=f[i]+" ";

        Debug.Log(v);
    }

    void print_m(){
        string v="";
        for(int i=0;i<l;i++)
            v+=m[i]+" ";

        Debug.Log(v);
    }
    // Update is called once per frame
    void update_ms(){
        fits.GetData(f);
        float sum=0;
        foreach(var a in f)
            sum+=a;
        float[] presum=new float[l];
        presum[0]=f[0];
        for(int i=1;i<l;i++){
            presum[i]=presum[i-1]+f[i];
            
        }
        
        int[] tmpm=new int[l];
        for(int i=0;i<l;i++)
            tmpm[i]=m[i];
        for(int i=0;i<l;i++){
            float seed=UnityEngine.Random.Range(0.0001f,sum);
            for(int j=1;j<l;j++){
                if(seed<=presum[j]&&seed>presum[j-1]){
                    m[i]=tmpm[j];
                    break;
                }
                m[i]=tmpm[0];
            }
        }
    }

    void exchange(int t){
        for(int i=0;i<t;i++){
            int a=UnityEngine.Random.Range(0,l);
            int b=UnityEngine.Random.Range(0,l);
            int hma=m[a]&0xf0;
            int lma=m[a]&0x0f;
            int hmb=m[b]&0xf0;
            int lmb=m[b]&0x0f;
            m[a]=hma|lmb;
            m[b]=lma|hmb;
        }
    }

    float timer=2f;
    float time=0;
    void Update()
    {
        // exchange(1);
        // print_m();
        if(timer>=2f&&time<4){
            run();
            print_fit();
            update_ms();
            exchange(1);
            print_m();
            timer=0;
            time++;
            if(time>=4){
                s.SetInt("m",m[0]);
                s.Dispatch(id2,texture.width/8,texture.width/8,128);
            }
        }
        timer+=Time.deltaTime;

    }
}
