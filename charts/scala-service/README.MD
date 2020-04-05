## Generic Scala Service Chart

This is a wrapper around the archtype chart.

## Service Monitoring

Quick Note on the ordering of what is monitoried
```bash
Prometheus Instance
- Matches to a ServiceMonitor label (prometheus: kube-prometheus)
    - Monitors a Service
        - Matches to service labels
            - On a defined namespace
```