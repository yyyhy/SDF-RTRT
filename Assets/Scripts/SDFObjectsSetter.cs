using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;

[ExecuteInEditMode]
public class SDFObjectsSetter : MonoBehaviour
{
    const int SEPHERE =0;
    const int BOX=1;
    struct SDF {
        public Vector3 center;
        //sephere param
        public float ra;
        //box param
        public Vector3 b;
        public float type;
        public float next;
        public float emit;
        public Vector3 emission;
        public float smooth;
    }
    public ComputeShader computeShader;
    //r also used as a flag
    /*
      \ .1 \ .2 \ .3 \ .4 \
      \    center    \  r \
      \type\next\emit\ smt\
      \   emission   \
    */
    public Matrix4x4[] sephereGroup;
    int cnt_sephere=0;
    /*
    \ .1 \ .2 \ .3 \ .4 \
    \    center    \  r \
    \      b       \
    \type\next\emit\ smt\
    \   emission   \
    */
    public Matrix4x4[] boxGroup;
    int cnt_box=0;
    public ComputeBuffer buffer;
    public Material mat;
    void Start()
    {
        
        int cnt=0;
        for(int i=0;i<sephereGroup.Length;i++){
            if(sephereGroup[i].m03!=0){
                cnt++;
                cnt_sephere++;
            }
        }
        for(int i=0;i<boxGroup.Length;i++){
            if(boxGroup[i].m03!=0){
                cnt++;
                cnt_box++;
            }
        }
        Debug.Log(cnt);
        int size1=sizeof(float)*13;
        int size2=sizeof(float)*1;
        int size=size1+size2;
        buffer=new ComputeBuffer(cnt,size);
        SDF[] sdfs=new SDF[cnt];
        for(int i=0;i<cnt_sephere;i++){
            SDF s=new SDF();
            s.type=SEPHERE;
            s.center=(Vector3)sephereGroup[i].GetRow(0);
            s.ra=sephereGroup[i].GetRow(0).w;
            s.emission=(Vector3)sephereGroup[i].GetRow(2);
            s.emit=sephereGroup[i].m13;
            s.smooth=sephereGroup[i].GetRow(1).w;
        }
        for(int i=0;i<cnt_box;i++){
            SDF s=new SDF();
            s.type=BOX;
            s.center=(Vector3)boxGroup[i].GetRow(0);
            s.b=boxGroup[i].GetRow(1);
            s.ra=boxGroup[i].GetRow(0).w;
            s.emission=(Vector3)boxGroup[i].GetRow(3);
            s.emit=boxGroup[i].GetRow(2).z;
            s.smooth=boxGroup[i].GetRow(2).w;
        }
        buffer.SetData(sdfs);
        mat.SetBuffer("sdfs",buffer);
        buffer.Release();
        buffer.Dispose();
        mat.SetFloat("_Size",cnt);
        
    }

    private void OnRenderObject() {
        
    }

    // Update is called once per frame
    void Update()
    {
        mat.SetVector("_ViewDir", Camera.main.transform.rotation.eulerAngles);
        if(sephereGroup.Length!=0)
            mat.SetMatrixArray("sephere",sephereGroup);
        if(boxGroup.Length!=0)
            mat.SetMatrixArray("box",boxGroup);
    }
}
