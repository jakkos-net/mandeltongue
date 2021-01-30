using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class SetRandomTimeOffset : MonoBehaviour
{
    [SerializeField] Material mat;
    void Start()
    {
        mat.SetFloat("_TimeOffset", ((UnityEngine.Time.realtimeSinceStartup.GetHashCode() + UnityEngine.Time.time.GetHashCode())%2257) * 5);
    }
}
