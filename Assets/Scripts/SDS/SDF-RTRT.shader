Shader "Hidden/RTPT_SDF"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _BgColor("BgColor",Color) = (1,1,1,1)
        _Near("Near",Range(0.1,10)) = 0.3
        _Fov("Fov",Range(30,90)) = 60
        _RTMaxTimes("RTMaxTimes",Range(1,4)) = 1
        _Accuracy("Accuray",Range(0.0005,0.5))=0.001
        _MaxStep("MaxStep",Range(16,256))=128
        _AntiNoise("AntiNoise",Range(0,3))=0
    }
    SubShader
    {
        // No culling or depth
        Cull Off ZWrite Off ZTest off
        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include"Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include"Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            

            //r also used as a flag
            /*
              \ .1 \ .2 \ .3 \ .4 \
              \    center    \  r \
              \type\next\emit\ smt\
              \   emission   \
            */
            uniform float4x4 sephere[32];
            struct sphere{
                float3 center;
                float r;
                bool emit;
                float3 emission;
                float smooth;
            };
            /*
              \ .1 \ .2 \ .3 \ .4 \
              \    center    \  r \
              \      b       \
              \type\next\emit\ smt\
              \   emission   \
            */
            uniform float4x4 box[32];
            struct boxx{
                float3 center;
                float b;
                bool emit;
                float3 emission;
                float smooth;
            };
            TEXTURE2D(_MainTex);
		    SAMPLER(sampler_MainTex);
            float _Fov;
            float _Near;
            float3 _ViewDir;
            float4 _BgColor;
            int _RTMaxTimes;
            float _Accuracy;
            int _MaxStep;
            int _AntiNoise;
            float _Size=1;
            
            float norm(float3 p) {
                return sqrt(p.x * p.x + p.y * p.y + p.z * p.z);
            }

            float norm(float2 p) {
                return sqrt(p.x * p.x + p.y * p.y);
            }

            float o2(float3 p){
                return p.x*p.x+p.y*p.y+p.z*p.z;
            }

            int time=0107;
            float ValueNoise(float3 pos) {
                pos*=time;
                time++;
                 float3 Noise_skew = pos + 0.2127 + pos.x * pos.y * pos.z * 0.3713;
                 float3 Noise_rnd = 4.789 * sin(489.123 * (Noise_skew));
                 return (sin((time+29))>0? 1:-1)*frac(Noise_rnd.x * Noise_rnd.y * Noise_rnd.z * (1.0 + Noise_skew.x));
            }
            #define UNION 0
            #define INTERSECTION 1
            #define SUBSTRACTION 2
            #define EPSILON 0.0001
            float opUnion(float d1, float d2,float k=-1) {
                if(k<=0)
                    return min(d1,d2);
                else{
                    float h=clamp(0.5+0.5*(d2-d1)/k,0.0,1.0);
                    return lerp(d2,d1,h)-k*h*(1-h);
                }
            }

            float opIntersection(float d1, float d2) {
                return max(d1, d2);
            }

            float opSubtraction(float d1, float d2) {
                return max(d1, -d2);
            }

            class Intersection {
                float3 pos;
                bool happen;
                float dis;
                int type;
                int index;
                bool emit;
                float smooth;
                float3 emission;
                float3 normal:NORMAL;
            };
            
            
            struct SDF {
                float3 center;
                //sephere param
                float ra;
                //box param
                float3 b;
                float type;
                float next;
                float emit;
                float3 emission;
                float smooth;
            
            #define SEPHERE 0
            #define BOX 1

                float sdf_func(float3 p) {
                    if (type == SEPHERE)
                        return norm(p - center) - ra;
                    else if(type == BOX){
                        p=p-center;
                        float3 q=abs(p)-b;
                        return norm(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
                    }
                    else
                        return 0x777ffff;
                }

                float3 normal(float3 p){
                    if(type==SEPHERE){
                        return normalize(p-center);
                    }
                    else if(type==BOX){
                        float dx = (sdf_func(p + float3(0.002, 0, 0)) - sdf_func(p)) / 0.002;
                        float dy = (sdf_func(p + float3(0, 0.002, 0)) - sdf_func(p)) / 0.002;
                        float dz = (sdf_func(p + float3(0, 0, 0.002)) - sdf_func(p)) / 0.002;
                        return normalize(float3(dx, dy, dz));
                    }
                    else
                        return 0;
                }

                void sample(out Intersection inter,out float pdf){
                    Intersection i;
                    if(type==SEPHERE){
                        float theta=2*3.14*_Time.x,phi=3.13*_Time.y;
                        float3 dir=float3(cos(phi),sin(phi)*cos(theta),sin(phi)*sin(theta));
                        i.pos=center+ra*dir;
                        i.normal=dir;
                        i.emission=emission*emit;
                        pdf=1.0/(4.0*3.14*ra*ra);
                        inter=i;
                    }
                    else{

                    }
                }

                bool intersect(float3 p, float3 ray) {
                    if (type == SEPHERE) {
                        float3 a=p-center;
                        float3 b=ray;
                        
                        float A=o2(b);
                        float B=2*(a.x*b.x+a.y*b.y+a.z*b.z);
                        float C=o2(a)-ra*ra;
                        float delta=B*B-4*A*C;
                        if(delta<0)
                            return false;
                        
                        float t1=(-B-sqrt(delta))/(2*A);
                        float t2=(-B+sqrt(delta))/(2*A);
                        if(t1<0&&t2<0)
                            return false;
                        return true;
                    }
                    else if(type==BOX){
                        float3 o=p;
                        float3 p1=abs(b)+center;
                        float3 p2=-abs(b)+center;
                        float tEnter=-99999;
                        float tExit=99999;
                        float t1,t2;
                        float3 invDir=float3(1/ray.x,1/ray.y,1/ray.z);
                        t1=(p1.x-o.x)*invDir.x;
                        t2=(p2.x-o.x)*invDir.x;
                        tEnter=max(min(t1,t2),tEnter);
                        tExit=min(max(t1,t2),tExit);
                        t1=(p1.y-o.y)*invDir.y;
                        t2=(p2.y-o.y)*invDir.y;
                        tEnter=max(min(t1,t2),tEnter);
                        tExit=min(max(t1,t2),tExit);
                        t1=(p1.z-o.z)*invDir.z;
                        t2=(p2.z-o.z)*invDir.z;
                        tEnter=max(min(t1,t2),tEnter);
                        tExit=min(max(t1,t2),tExit);


                        return tExit>=-EPSILON&&tEnter-tExit<=EPSILON;
                    }
                    return 0;
                }
            };

            int initSDF(SDF sdfs[512]){
                int sdf_size=0;
                for(int i=0;i<16;i++){
                    if(sephere[i][0].w!=0){
                        sdfs[sdf_size].center=sephere[i][0].xyz;
                        sdfs[sdf_size].ra=sephere[i][0].w;
                        sdfs[sdf_size].type=SEPHERE;
                        sdfs[sdf_size].next=sephere[i][1].y;
                        sdfs[sdf_size].emit=sephere[i][1].z;
                        sdfs[sdf_size].smooth=sephere[i][1].w;
                        sdfs[sdf_size].emission=sephere[i][2].xyz;
                        sdf_size++;
                    }
                    else
                         break;
                }
                for(int i=0;i<32;i++){
                    if(box[i][0].w!=0){
                        sdfs[sdf_size].center=box[i][0].xyz;
                        sdfs[sdf_size].ra=box[i][0].w;
                        sdfs[sdf_size].b=box[i][1].xyz;
                        sdfs[sdf_size].type=BOX;
                        sdfs[sdf_size].next=box[i][2].y;
                        sdfs[sdf_size].emit=box[i][2].z;
                        sdfs[sdf_size].smooth=box[i][2].w;
                        sdfs[sdf_size].emission=box[i][3].xyz;
                        sdf_size++;
                    }
                    else
                         break;
                }
                return sdf_size;
            }

            void sampleLight(out Intersection inter,out float pdf){
                SDF s;
                for(int i=0;i<32;i++){
                    if(sephere[i][0].w!=0&&sephere[i][1].z==1){
                        s.center=sephere[i][0].xyz;
                        s.ra=sephere[i][0].w;
                        s.type=SEPHERE;
                        s.emission=sephere[i][2].xyz;
                        s.emit=1;
                        float theta=2*3.14*_Time.x,phi=3.13*_Time.y;
                        float3 dir=float3(cos(phi),sin(phi)*cos(theta),sin(phi)*sin(theta));
                        inter.pos=s.center+s.ra*dir;
                        inter.normal=dir;
                        inter.emission=s.emission*s.emit;
                        pdf=1.0/(4.0*3.14*s.ra*s.ra);
                        // s.sample(inter,pdf);
                        return;
                    }
                }
            }

            bool intersect(float3 o,float dir,int ignore=-1){
                SDF s;
                for(int i=0;i<32;i++){
                    if(sephere[i][0].w!=0&&sephere[i][1].z==0){
                        s.center=sephere[i][0].xyz;
                        s.ra=sephere[i][0].w;
                        s.type=SEPHERE;
                        if(s.intersect(o,dir))
                            return true;
                    }
                    if(box[i][0].w!=0&&box[i][2].z==0){
                        s.center=box[i][0].xyz;
                        s.b=box[i][1].xyz;
                        s.type=BOX;
                        if(s.intersect(o,dir))
                            return true;
                    }
                    if(sephere[i][0].w==0&&box[i][0].w!=0)
                        return false;
                }

                return false;
            }

            float3 getNormal(float3 p, SDF s) {
                float dx = (s.sdf_func(p + float3(0.001, 0, 0)) - s.sdf_func(p)) / 0.001;
                float dy = (s.sdf_func(p + float3(0, 0.001, 0)) - s.sdf_func(p)) / 0.001;
                float dz = (s.sdf_func(p + float3(0, 0, 0.001)) - s.sdf_func(p)) / 0.001;
                return normalize(float3(dx, dy, dz));
            }

            float3 sample(float3 ray,float3 normal,float smooth=1){
                float3 refRay = normalize(reflect(ray,normal));
                float offx=ValueNoise(ray*_Time.x);
                float offy=ValueNoise(ray*_Time.x);
                float offz=ValueNoise(ray*_Time.x);
                float3 offr=float3(offx,offy,offz);
                offr*=(1-smooth);
                return normalize(refRay+offr);
            }
#define INF 0x777ffff
            Intersection getDisInfo(float3 p) {
                float dis=INF;
                SDF s;
                int type=-1;
                int index=-1;
                Intersection info;
                info.dis=INF;
                for(int i=0;i<32;i++){
                    if(sephere[i][0].w!=0){
                        s.center=sephere[i][0].xyz;
                        s.ra=sephere[i][0].w;
                        s.type=SEPHERE;
                        float tmp=opUnion(dis,s.sdf_func(p));
                        if(tmp<dis){
                            dis=tmp;
                            index=i;
                            type=SEPHERE;
                        }
                    }
                    if(box[i][0].w!=0){
                        s.b=box[i][1].xyz;
                        s.center=box[i][0].xyz;
                        s.type=BOX;
                        float tmp=opUnion(dis,s.sdf_func(p));
                        if(tmp<dis){
                            dis=tmp;
                            index=i;
                            type=BOX;
                        }
                    }
                    if(sephere[i][0].w==0&&box[i][0].w==0)
                        break;
                }
                if(index!=-1){
                    info.dis=dis;
                    info.type=type;
                    info.index=index;
                    info.pos=p;
                    if(type==SEPHERE){
                        s.center=sephere[index][0].xyz;
                        s.ra=sephere[index][0].w;
                        s.type=SEPHERE;
                        info.emit=sephere[index][1].z;
                        info.emission=sephere[index][2].xyz;
                        info.smooth=sephere[index][1].w;
                    }
                    else if(type==BOX){
                        s.b=box[index][1].xyz;
                        s.center=box[index][0].xyz;
                        s.type=BOX;
                        info.emit=box[index][2].z;
                        info.emission=box[index][3].xyz;
                        info.smooth=box[index][2].w;
                    }
                    info.normal=s.normal(p);
                }

                return info;
            }

            float3 getNormal(float3 p) {
                float dx = (getDisInfo(p + float3(0.001, 0, 0)).dis - getDisInfo(p).dis) / 0.001;
                float dy = (getDisInfo(p + float3(0, 0.001, 0)).dis - getDisInfo(p).dis) / 0.001;
                float dz = (getDisInfo(p + float3(0, 0, 0.001)).dis - getDisInfo(p).dis) / 0.001;
                return normalize(float3(dx, dy, dz));
            }

            Intersection getIntersection(float3 p,float3 ray){
                float totol=0;
                int i=0;
                Intersection info;
                info.happen=false;
                for (; i < _MaxStep; i++) {
                    float3 pos = totol * ray + p;
                    info = getDisInfo(pos);
                    if (info.dis < _Accuracy && info.dis>-_Accuracy) {info.happen=true;return info;}
                    totol += info.dis;
                }

                return info;
            }

            float3 draw(float3 camPos, float3 ray) {
                float3 col = 0;
                float3 pos;
                Intersection info;
                float3 o=camPos;
                float3 d=ray;
                float3 factors[32];
                float3 cols[32];
                factors[0]=float3(1,1,1);
                int index=0;
                bool happen=false;
                float3 basecol=0;
                for(int j=0;j<_RTMaxTimes*2;j++) {
                    float3 ldir=0;
                    info=getIntersection(o,d);
                    pos=info.pos;
                    if (!info.happen){
                        cols[index]=ldir;
                        break;
                    }
                    happen=true;
                    if(info.emit){
                        cols[index]=info.emission;
                        break;
                    }
                    
                    //calculate the color
                   
                    Intersection lightInter;
                    float lightPdf;   
                    //sampleLight(lightInter,lightPdf);
                    SDF s;
                    for(int i=0;i<32;i++){
                        if(sephere[i][0].w!=0&&sephere[i][1].z==1){
                            s.center=sephere[i][0].xyz;
                            s.ra=sephere[i][0].w;
                            s.type=SEPHERE;
                            s.emission=sephere[i][2].xyz;
                            s.emit=1;
                            float theta=2*3.14*ValueNoise(pos*_Time.x),phi=3.13*ValueNoise(pos*_Time.x);
                            float3 dir=float3(cos(phi),sin(phi)*cos(theta),sin(phi)*sin(theta));
                            lightInter.pos=s.center+s.ra*dir;
                            lightInter.normal=dir;
                            lightInter.emission=s.emission*s.emit;
                            lightPdf=1.0/(4.0*3.14*s.ra*s.ra);
                            break;
                        }
                    }
                    
                    float3 obj2light=lightInter.pos-pos;
                    
                    float3 lightDir=normalize(obj2light);
                    float dis=o2(obj2light);
                    
                    basecol=(1/dis)*info.emission*(dot(info.normal,obj2light)*0.5+0.5)*lightInter.emission+float3(0.1,0.1,0.1);
                    
                    Intersection inte=getIntersection(pos+lightDir*0.1,lightDir);
                    float rdis=norm(inte.pos-pos);
                    if(inte.emit){
                        ldir=lightInter.emission/dis/lightPdf*(dot(info.normal,lightDir)>0? 1.0/3.14:0.0)
                        *dot(lightDir,info.normal)*dot(-lightDir,lightInter.normal)*info.emission;
                        ldir=ldir*0.9+basecol*0.1;
                    }
                    
                    //calculate next ray
                    float3 nor = info.normal;
                    float3 refRay = sample(d,nor,info.smooth);
                    d = refRay;
                    o=pos+refRay*0.1;
                    Intersection info1=getIntersection(o,d);
                    if(info1.happen&&!info1.emit){
                        float pdf=(dot(refRay,info.normal)>0? 0.5:0);
                        float3 factor=(dot(refRay,info.normal)>0? 0.2:0)
                                    *dot(refRay,info.normal)/pdf/(1.0-1.0/(2*_RTMaxTimes))*info.emission;
                        cols[index]=ldir;
                        factors[++index]=factor;
                    }
                    else{
                        cols[index]=ldir;
                        break;
                    }
                   
                }
                if (index==0)
                    return _BgColor.xyz;
                for(int m=index+1;m--;m>=0){
                    col=(col+cols[m])*factors[m];
                }
                return col;
            }

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = TransformObjectToHClip(v.vertex);
                o.uv = v.uv;
                return o;
            }

            real4 frag(v2f i) : SV_Target
            {
                SDF sdfs[512];
                int size=initSDF(sdfs);

                float aspect = _ScreenParams.y / _ScreenParams.x;
                float2 uv = i.uv * 2 - 1;

                float3 camPosWS = _WorldSpaceCameraPos;
                float3 rayWS;
                float t = tan(_Fov * 3.14 / 180) * _Near;
                float r = t / aspect;
                float2 offset = float2(uv.x *r, uv.y*t );
                float2 noise=float2(0.01,0.01);
                float3x3 mx = { 1,0,0,
                             0,cos(_ViewDir.x * 3.14 / 180),-sin(_ViewDir.x * 3.14 / 180),
                             0,sin(_ViewDir.x * 3.14 / 180),cos(_ViewDir.x * 3.14 / 180), };
                float3x3 my = { cos(_ViewDir.y * 3.14 / 180),0,sin(_ViewDir.y * 3.14 / 180),
                             0,1,0,
                             -sin(_ViewDir.y * 3.14 / 180),0,cos(_ViewDir.y * 3.14 / 180), };
                float3x3 mz = { cos(_ViewDir.z * 3.14 / 180),-sin(_ViewDir.z * 3.14 / 180),0,
                             sin(_ViewDir.z * 3.14 / 180),cos(_ViewDir.z * 3.14 / 180),0,
                             0,0,1, };
                float3 col=0;
                rayWS = normalize(float3(offset, 2));
                rayWS = mul(mz, mul(my, mul(mx, rayWS)));
                rayWS=normalize(rayWS);
                int times=0;
                for(int i=0;i<_AntiNoise+1;i++){
                    float3 colt=draw(camPosWS,rayWS);
                    if(colt.x>=0&&colt.y>=0&&colt.z>=0){
                        col+=colt;
                        times++;
                    }
                }
                // if(times==0){
                //     float2 u=(uv+1)/2;
                //     real4 tex = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,u);
                //     return tex;
                // }
                return real4(col/(times),1);
            }
            ENDHLSL
        }
    }
}
