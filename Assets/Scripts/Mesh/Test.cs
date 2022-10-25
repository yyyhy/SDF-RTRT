using UnityEngine;
using System.Collections;
using System.Collections.Generic;

public class Test : MonoBehaviour
{
    public MeshFilter cube_mesh;
    // Use this for initialization
    [Range(1, 4)]
    public int Level = 2;
    
    public class Edge
    {
        Vector3 v1;
        Vector3 v2;
        public Edge(Vector3 v1, Vector3 v2)
        {
            this.v1 = v1;
            this.v2 = v2;
        }

        public bool VectorEq(Vector3 v1,Vector3 v2)
        {
            return Mathf.Approximately(v1.x, v2.x) && Mathf.Approximately(v1.y, v2.y) && Mathf.Approximately(v1.z, v2.z);
        }
        public bool equal(Edge edge)
        {
            return (VectorEq(v1,edge.v1) && VectorEq(v2, edge.v2)) || (VectorEq(v2, edge.v1) && VectorEq(v1, edge.v2));
        }
    }
    public List<Vector3> FindVerticesByEdge(Vector3[] vs,int[] ts,Edge edge)
    {
        List<Vector3> result = new List<Vector3>();
        for(int i = 0; i < ts.Length/3; i ++)
        {
            Vector3 t0_ = vs[ts[i * 3 + 0]];
            Vector3 t1_ = vs[ts[i * 3 + 1]];
            Vector3 t2_= vs[ts[i * 3 + 2]];
            if (edge.equal(new Edge(t0_, t1_)))
            {
                bool has = false;
                foreach (var v in result)
                    if (v == t2_)
                    {
                        has = true;
                        break;
                    }
                if(!has)
                    result.Add(t2_);
            } 
            else if (edge.equal(new Edge(t2_, t0_)))
            {
                bool has = false;
                foreach (var v in result)
                    if (v == t1_)
                    {
                        has = true;
                        break;
                    }
                if (!has)
                    result.Add(t1_);
            }
            else if (edge.equal(new Edge(t2_, t1_)))
            {
                bool has = false;
                foreach (var v in result)
                    if (v == t0_)
                    {
                        has = true;
                        break;
                    }
                if (!has)
                    result.Add(t0_);
            }
        }

        return result;
    }

    public List<Vector3> FindVerticesConnectToPoint(Vector3[] vs, int[] ts, Vector3 t0)
    {
        List<Vector3> result = new List<Vector3>();
        for (int i = 0; i < ts.Length/3; i ++)
        {
            Vector3 t0_ = vs[ts[i * 3 + 0]];
            Vector3 t1_ = vs[ts[i * 3 + 1]];
            Vector3 t2_ = vs[ts[i * 3 + 2]];
            if (t0 == t0_)
            {
                if (!result.Contains(t1_))
                    result.Add(t1_);
                if (!result.Contains(t2_))
                    result.Add(t2_);
            }
            if (t0 == t1_)
            {
                if (!result.Contains(t0_))
                    result.Add(t0_);
                if (!result.Contains(t2_))
                    result.Add(t2_);
            }
            if (t0 == t2_)
            {
                if (!result.Contains(t1_))
                    result.Add(t1_);
                if (!result.Contains(t0_))
                    result.Add(t0_);
            }
        }
        return result;
    }

    public Vector3 LoopSubdivideOldVertex(List<Vector3> points,Vector3 p)
    {
        int n = points.Count;
        float u = n == 3 ? 3f / 16f : 3f / (8f * n);

        Vector3 v = Vector3.zero;
        points.ForEach((val) => { v += val; }) ;
        return (1 - n * u) * p + v*u;
    }

    public Vector3 LoopSubdivideNewVertex(List<Vector3> points, Vector3 p,Vector3 v1,Vector3 v2)
    {
        if (points.Count == 1)
            return 3f / 8f * (v1 + v2) + 2f / 8f * (points[0]);
        if (points.Count > 1)
            return 3f / 8f * (v1 + v2) + 1f / 8f * (points[0]+points[1]);
        return Vector3.zero;
    }

    void Start()
    {
        for (int t = 0; t < Level; t++)
        {
            Mesh cube = this.cube_mesh.mesh;

            
            List<Vector3> vertices = new List<Vector3>();
            List<int> triangles = new List<int>();
            List<Vector3> normals = new List<Vector3>();
            List<Vector2> uv = new List<Vector2>();
            List<Vector4> tangents = new List<Vector4>();


            
            for (int i = 0; i < cube.triangles.Length / 3; i++)
            {
                Vector3 t0 = cube.vertices[cube.triangles[i * 3 + 0]];
                Vector3 t1 = cube.vertices[cube.triangles[i * 3 + 1]];
                Vector3 t2 = cube.vertices[cube.triangles[i * 3 + 2]];
                Vector3 t3 = Vector3.Lerp(t0, t1, 0.5f);
                var t3Attribute = FindVerticesByEdge(cube.vertices, cube.triangles, new Edge(t0, t1));

                Vector3 t4 = Vector3.Lerp(t1, t2, 0.5f);
                var t4Attribute = FindVerticesByEdge(cube.vertices, cube.triangles, new Edge(t2, t1));

                Vector3 t5 = Vector3.Lerp(t0, t2, 0.5f);
                var t5Attribute = FindVerticesByEdge(cube.vertices, cube.triangles, new Edge(t0, t2));
                //Debug.Log( t3Attribute.Count+" "+t4Attribute.Count +""+ t5Attribute.Count);

                t3 = LoopSubdivideNewVertex(t3Attribute, t3, t0, t1);
                t4 = LoopSubdivideNewVertex(t4Attribute, t4, t2, t1);
                t5 = LoopSubdivideNewVertex(t5Attribute, t5, t0, t2);

                int count = vertices.Count;

                t0 = LoopSubdivideOldVertex(FindVerticesConnectToPoint(cube.vertices, cube.triangles, t0), t0);
                t1 = LoopSubdivideOldVertex(FindVerticesConnectToPoint(cube.vertices, cube.triangles, t1), t1);
                t2 = LoopSubdivideOldVertex(FindVerticesConnectToPoint(cube.vertices, cube.triangles, t2), t2);
                //插入顶点坐标到顶点数组vertices中，vertices填充完毕
                vertices.Add(t0); // 索引为count + 0
                vertices.Add(t1); // 索引为count + 1
                vertices.Add(t2); // 索引为count + 2
                vertices.Add(t3); // 索引为count + 3
                vertices.Add(t4); // 索引为count + 4
                vertices.Add(t5); // 索引为count + 5


                //-------------------------------------------------------------
                //插入三角形顶点索引到三角形数组triangles中，triangles填充完毕
                triangles.Add(count + 0); triangles.Add(count + 3); triangles.Add(count + 5);
                triangles.Add(count + 3); triangles.Add(count + 1); triangles.Add(count + 4);
                triangles.Add(count + 4); triangles.Add(count + 2); triangles.Add(count + 5);
                triangles.Add(count + 3); triangles.Add(count + 4); triangles.Add(count + 5);

                //-------------------------------------------------------------
                //和上面获得顶点坐标的做法一样，获得各个normals法线坐标
                Vector3 n0 = cube.normals[cube.triangles[i * 3 + 0]];
                Vector3 n1 = cube.normals[cube.triangles[i * 3 + 1]];
                Vector3 n2 = cube.normals[cube.triangles[i * 3 + 2]];

                Vector3 n3 = Vector3.Lerp(n0, n1, 0.5f);
                Vector3 n4 = Vector3.Lerp(n1, n2, 0.5f);
                Vector3 n5 = Vector3.Lerp(n0, n2, 0.5f);

                //插入法线坐标到法线数组normals中，normals填充完毕
                normals.Add(n0);
                normals.Add(n1);
                normals.Add(n2);
                normals.Add(n3);
                normals.Add(n4);
                normals.Add(n5);

                //-------------------------------------------------------------
                //和上面获得顶点坐标的做法一样，获得各个uv纹理坐标
                Vector2 uv0 = cube.uv[cube.triangles[i * 3 + 0]];
                Vector2 uv1 = cube.uv[cube.triangles[i * 3 + 1]];
                Vector2 uv2 = cube.uv[cube.triangles[i * 3 + 2]];

                Vector2 uv3 = Vector3.Lerp(uv0, uv1, 0.5f);
                Vector2 uv4 = Vector3.Lerp(uv1, uv2, 0.5f);
                Vector2 uv5 = Vector3.Lerp(uv0, uv2, 0.5f);

                //插入纹理坐标到纹理数组uv中，uv填充完毕
                uv.Add(uv0);
                uv.Add(uv1);
                uv.Add(uv2);
                uv.Add(uv3);
                uv.Add(uv4);
                uv.Add(uv5);

                //-------------------------------------------------------------
                //和上面获得顶点坐标的做法一样，获得各个tangents切线坐标
                Vector4 tan0 = cube.tangents[cube.triangles[i * 3 + 0]];
                Vector4 tan1 = cube.tangents[cube.triangles[i * 3 + 1]];
                Vector4 tan2 = cube.tangents[cube.triangles[i * 3 + 2]];

                Vector4 tan3 = Vector3.Lerp(tan0, tan1, 0.5f);
                Vector4 tan4 = Vector3.Lerp(tan1, tan2, 0.5f);
                Vector4 tan5 = Vector3.Lerp(tan0, tan2, 0.5f);

                //插入切线坐标到切线数组tangents中，tangents填充完毕
                tangents.Add(tan0);
                tangents.Add(tan1);
                tangents.Add(tan2);
                tangents.Add(tan3);
                tangents.Add(tan4);
                tangents.Add(tan5);
            }

            //传递给自己的Mesh并重新绘制网格
            Mesh self_mesh = this.GetComponent<MeshFilter>().mesh;
            self_mesh.Clear();
            self_mesh.vertices = vertices.ToArray();//List转换为Array
            self_mesh.triangles = triangles.ToArray();
            self_mesh.normals = normals.ToArray();
            self_mesh.uv = uv.ToArray();
            self_mesh.tangents = tangents.ToArray();

            self_mesh.RecalculateBounds();
        }
        //没有删除重复的顶点，有待完善
    }

    // Update is called once per frame
    void Update()
    {

    }
}