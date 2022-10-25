using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class MMD : MonoBehaviour
{
    // Start is called before the first frame update
    public SphereCollider[] sphereColliders;
    public MeshFilter mesh_plane;
    public ComputeBuffer pointsBuffer;
    public ComputeBuffer springsBuffer;
    public ComputeBuffer areasBuffer;
    public float k=4f;
    public float restLength=0.5f;
    public ComputeShader calcForce;
    public ComputeShader calcPos;
    struct point_data{
        public int locked;
        public float mass;
        public Vector3 pos;
        public Vector3 force;
        public Vector3 v;
        public int id;
    };
    int pointSize;
    point_data[] pointDatas;
    struct spring_data{
        public float k;
        public float rest_length;
        public int p1;
        public int p2;
    };
    int springSize;
    spring_data[] springDatas;
    struct ForbiddenArea{
        public Vector3 center;
        public float r;
    };
    int areaSize;
    ForbiddenArea[] areaDatas;
    int id1;
    int id2;
    Vector3[] vertices;
    int[] triangles;
    void Start()
    {
        Mesh plane=mesh_plane.mesh;
        vertices = plane.vertices;
        triangles = plane.triangles;
        
        pointSize=sizeof(float)*10+sizeof(int)*2;
        springSize=sizeof(float)*2+sizeof(int)*2;
        areaSize=sizeof(float)*4;
        int cnt=vertices.Length;
        pointsBuffer=new ComputeBuffer(cnt,pointSize);      
        pointDatas=new point_data[cnt];
        //Debug.Log(cnt);
        for(int i=0;i<cnt;i++){
            pointDatas[i]=new point_data();
            Vector3 pos=vertices[i];
            pointDatas[i].pos=pos;
            pointDatas[i].force=Vector3.zero;
            pointDatas[i].mass=0.01f;
            pointDatas[i].v=Vector3.zero;
            pointDatas[i].locked=1;
            pointDatas[i].id = i;
        }
        List<spring_data> springList=new List<spring_data>();
        for(int i = 0; i < plane.triangles.Length / 3; i++)
        {
            int t0 = plane.triangles[i * 3 + 0];
            int t1 = plane.triangles[i * 3 + 1];
            int t2 = plane.triangles[i * 3 + 2];
            Vector3 v01=vertices[t0]-vertices[t1];
            Vector3 v12=vertices[t1]-vertices[t2];
            Vector3 v02=vertices[t0]-vertices[t2];
            float dot0=Vector3.Dot(v01,v02);
            float dot1=Vector3.Dot(v01,v12); 
            float dot2=Vector3.Dot(v12,v02);
            if(Mathf.Approximately(dot0,0)){
                springList.Add(new spring_data() { k = 10,p1=t0,p2=t1,rest_length=restLength }) ;
                springList.Add(new spring_data() { k = 10, p1 = t0, p2 = t2, rest_length = restLength });
            }
            if(Mathf.Approximately(dot1,0)){
                springList.Add(new spring_data() { k = 10,p1=t1,p2=t0,rest_length=restLength }) ;
                springList.Add(new spring_data() { k = 10, p1 = t1, p2 = t2, rest_length = restLength });
            }
            if(Mathf.Approximately(dot2,0)){
                springList.Add(new spring_data() { k = 10,p1=t2,p2=t0,rest_length=restLength }) ;
                springList.Add(new spring_data() { k = 10, p1 = t2, p2 = t1, rest_length = restLength });
            }
            
        }
        
        springDatas=springList.ToArray();
        springsBuffer = new ComputeBuffer(springDatas.Length, springSize);
        pointsBuffer.SetData(pointDatas);
        springsBuffer.SetData(springDatas);
       
        int al=sphereColliders.Length;
        id1 = calcForce.FindKernel("CSMain");
        id2 = calcPos.FindKernel("CSMain");
        
        areaDatas = new ForbiddenArea[al];
        areasBuffer = new ComputeBuffer(al, areaSize);
        for (int i = 0; i < al; i++)
        {
            areaDatas[i] = new ForbiddenArea();
            areaDatas[i].center = Vector3.zero;
            areaDatas[i].r = 4;
        }
        areasBuffer.SetData(areaDatas);
        calcPos.SetBuffer(id2, "areas", areasBuffer);
        calcForce.SetBuffer(id1,"springs",springsBuffer);
        calcForce.SetBuffer(id1,"points",pointsBuffer);
        calcPos.SetBuffer(id2,"points",pointsBuffer);
        calcPos.SetInt("size",al);

        
    }

    void updatePos(){
        
        point_data[] p=new point_data[vertices.Length];
        pointsBuffer.GetData(p);
        for(int i=0;i<p.Length;i++){
            vertices[i]=p[i].pos;
            
        }
        Mesh self_mesh = this.GetComponent<MeshFilter>().mesh;
        self_mesh.Clear();
        self_mesh.vertices = vertices;
        self_mesh.triangles = triangles;
        
        self_mesh.RecalculateNormals();
        self_mesh.RecalculateTangents();
        self_mesh.RecalculateBounds();
    }
    float timer=0;
    void FixedUpdate()
    {
        timer+=Time.fixedDeltaTime;
        if(timer>0){
            
            calcForce.Dispatch(id1,5,10,100);
            calcPos.Dispatch(id2,5,10,100);
            updatePos();
            timer=0;
        }
    }
}
