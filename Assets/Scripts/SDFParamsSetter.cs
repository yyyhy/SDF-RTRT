using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;

[ExecuteInEditMode]
public class SDFParamsSetter : MonoBehaviour
{
    // Start is called before the first frame update
    public Material mat;
    [Range(16,256)]
    public int MaxStep=128;
    [Range(1,4)]
    public int RTMaxTimes=2;
    [Range(0.0008f,0.5f)]
    public double Accuracy=0.001f;
    [Range(0,3)]
    public int AntiNoise=0;
    public Color BgColor;
    void Start()
    {
        
    }

    // Update is called once per frame
    void Update()
    {
        mat.SetColor("_BgColor",BgColor);
        mat.SetFloat("_Accuracy",(float)Accuracy);
        mat.SetInt("_RTMaxTimes",RTMaxTimes);
        mat.SetInt("_MaxStep",MaxStep);
        mat.SetInt("_AntiNoise",AntiNoise);
    }
}
