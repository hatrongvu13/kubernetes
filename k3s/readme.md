Tạo base64 để cấu hình
```shell
echo -n '{"auths":{"ghcr.io":{"username":"your-username","password":"your-github-token","email":"your-email@example.com","auth":"'"$(echo -n "your-username:your-github-token" | base64)"'"}}}' | base64 -w 0

```

FIle cấu hình :
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: ghcr-secret
  namespace: default
type: kubernetes.io/dockerconfigjson
data:
  .dockerconfigjson: |
    eyJhdXRocyI6eyJnaGNyLmlvIjp7InVzZXJuYW1lIjoieW91ci11c2VybmFtZSIsInBhc3N3b3JkIjoieW91ci1naXRodWItdG9rZW4iLCJlbWFpbCI6InlvdXItZW1haWxAZXhhbXBsZS5jb20iLCJhdXRoIjoieW91ci1iYXNlNjQtYXV0aC1zdHJpbmcifX19

```