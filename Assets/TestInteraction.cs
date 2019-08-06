using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class TestInteraction : MonoBehaviour
{
    public ScanVisualManager ScanVisual;
    public float BurstTime;
    private float burstTimeRemaining;

    private void Start()
    {
        burstTimeRemaining = BurstTime;
    }

    void Update()
    {
        UpdateScanVisualPosition();
        UpdateBurst();
    }

    private void UpdateBurst()
    {
        burstTimeRemaining -= Time.deltaTime;
        if(burstTimeRemaining < 0)
        {
            ScanVisual.DoABurst();
            burstTimeRemaining = BurstTime;
        }
    }

    private void UpdateScanVisualPosition()
    {
        Ray cameraRay = new Ray(Camera.main.transform.position, Camera.main.transform.forward);
        RaycastHit hit;
        if (Physics.Raycast(cameraRay, out hit))
        {
            ScanVisual.transform.position = hit.point;
            ScanVisual.transform.forward = -hit.normal;
        }
    }
}
