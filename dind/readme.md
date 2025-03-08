# Hướng dẫn triển khai docker in docker
## Mục đích để kết hợp với jenkins để thực hiện CI | CD
### Môi trường : 
 * Kubernetes: K3S cluster
 * File triển khai 
``` yaml
apiVersion: v1
kind: Pod
metadata:
  name: dind
  labels:
    app: dind
spec:
  containers:
  - name: dind
    image: docker:dind
    securityContext:
      privileged: true
    ports:
    - containerPort: 2375
      protocol: TCP
    env:
    - name: DOCKER_TLS_CERTDIR
      value: ""
---
apiVersion: v1
kind: Service
metadata:
  name: dind
spec:
  type: ClusterIP
  ports:
  - port: 2375
    targetPort: 2375
  selector:
    app: dind
```

* Triển khai:
```shell
  kubectl apply -f dind.yaml
```

* Lấy địa chỉ Dind trong cluster
```shell
  kubectl get svc dind
```
