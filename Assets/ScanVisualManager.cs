using System;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;

public class ScanVisualManager : MonoBehaviour
{
    public bool TestBurst;

    public Material ParticleMaterial;
    public Material SurfaceMaterial;
    public ComputeShader ParticleCompute;
    public float ParticleLifespan;
    public int ParticlesCount;
    public float ParticleSize;
    [Range(0, 10)]
    public float Spread;
    public float BurstTime;
    public Mesh Mesh;

    private ComputeBuffer quadPoints;
    private const int QuadStride = 12;
    private int particleComputeKernel;
    private Vector3 burstPoint;
    
    private float burstness;

    struct DustMote
    {
        public Vector3 CurrentPos;
        public Vector3 Normal;
        public float LifetimeRemaining;
        public float RandomX;
        public float RandomY;
    }
    
    private const int GroupsCount = 128;
    
    private ComputeBuffer _dynamicDataBuffer;
    private const int DustMoteStride = sizeof(float) * 3 // Current Pos
        + sizeof(float) * 3 // Normal
        + sizeof(float) // Lifetime
        + sizeof(float) // Random X
        + sizeof(float); // Random Y


    public void DoABurst()
    {
        burstness = 0;
        burstPoint = transform.position;
    }

    private void Start()
    {
        particleComputeKernel = ParticleCompute.FindKernel("UpdateParticles");
        quadPoints = GetQuadPoints();
        _dynamicDataBuffer = GetDynamicDataBuffer();
        burstness = 10000;
    }

    private void Update()
    {
        burstness += Time.deltaTime;
        if (TestBurst)
        {
            TestBurst = false;
            DoABurst();
        }
        UpdateAllParticles();
        UpdateMaterials();
    }

    private ComputeBuffer GetDynamicDataBuffer()
    {
        DustMote[] data = new DustMote[ParticlesCount];
        for (int i = 0; i < ParticlesCount; i++)
        {
            Vector3 sphere = UnityEngine.Random.insideUnitSphere;
            float lifetime = ParticleLifespan * UnityEngine.Random.value;
            data[i] = new DustMote() {
                LifetimeRemaining = lifetime,
                RandomX = sphere.x,
                RandomY = sphere.y
            };
        }
        ComputeBuffer ret = new ComputeBuffer(ParticlesCount, DustMoteStride);
        ret.SetData(data);
        return ret;
    }

    private ComputeBuffer GetQuadPoints()
    {
        ComputeBuffer ret = new ComputeBuffer(6, QuadStride);
        ret.SetData(new[]
        {
            new Vector3(-.5f, .5f),
            new Vector3(.5f, .5f),
            new Vector3(.5f, -.5f),
            new Vector3(.5f, -.5f),
            new Vector3(-.5f, -.5f),
            new Vector3(-.5f, .5f)
        });
        return ret;
    }

    private void UpdateAllParticles()
    {
        ParticleCompute.SetFloat("_DeltaTime", Time.deltaTime);
        ParticleCompute.SetFloat("_Lifespan", ParticleLifespan);

        int groups = Mathf.CeilToInt((float)ParticlesCount / GroupsCount);
        ParticleCompute.SetBuffer(particleComputeKernel, "_DynamicData", _dynamicDataBuffer);
        ParticleCompute.Dispatch(particleComputeKernel, groups, 1, 1);
    }

    private void UpdateMaterials()
    {
        ParticleCompute.SetVector("_CursorPos", transform.position);
        ParticleCompute.SetVector("_CursorUp", transform.up);
        ParticleCompute.SetVector("_CursorRight", transform.right);
        ParticleCompute.SetFloat("_Spread", Spread);
        ParticleCompute.SetFloat("_Burstness", burstness);

        float burstAlpha = GetBurstAlpha();
        ParticleMaterial.SetFloat("_BurstAlpha", burstAlpha);
        ParticleMaterial.SetVector("_BurstPoint", burstPoint);
        ParticleMaterial.SetFloat("_Burstness", burstness);
        ParticleMaterial.SetFloat("_CardSize", ParticleSize);
        ParticleMaterial.SetBuffer("_DynamicData", _dynamicDataBuffer);
        ParticleMaterial.SetFloat("_Lifespan", ParticleLifespan);
        ParticleMaterial.SetMatrix("_MasterTransform", transform.localToWorldMatrix);
        ParticleMaterial.SetBuffer("_QuadPoints", quadPoints);

        SurfaceMaterial.SetVector("_CursorPos", transform.position);
        SurfaceMaterial.SetFloat("_Burstness", burstness);
        SurfaceMaterial.SetFloat("_BurstAlpha", burstAlpha);
        SurfaceMaterial.SetVector("_BurstPoint", burstPoint);
    }

    private float GetBurstAlpha()
    {
        float ret = burstness / BurstTime;
        ret = Mathf.Clamp01(ret);
        return ret;
    }

    private void OnDestroy()
    {
        quadPoints.Dispose();
        _dynamicDataBuffer.Dispose();
    }

    private void OnRenderObject()
    {
        ParticleMaterial.SetPass(0);
        Graphics.DrawProcedural(MeshTopology.Triangles, 6, ParticlesCount);
    }
}
