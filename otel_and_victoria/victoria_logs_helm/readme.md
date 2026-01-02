https://docs.victoriametrics.com/helm/victoria-logs-cluster/

```
helm repo add vm https://victoriametrics.github.io/helm-charts/
helm repo update
helm show values vm/victoria-logs-cluster > values.yaml
helm template vlc vm/victoria-logs-cluster -f values.yaml
```