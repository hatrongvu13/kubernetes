# Hướng dẫn triển khai Jenkins CI | CD trên kubernetes

## Mục tiêu kết hợp được với github và docker in docker để có thể triển khai dự án bình thường

### Môi trường thực hiện: K3s cluster local
* Triển khai với file deployment sau:
``` yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: jenkins
spec:
  replicas: 1
  selector:
    matchLabels:
      app: jenkins
  template:
    metadata:
      labels:
        app: jenkins
    spec:
      containers:
        - name: jenkins
          image: jenkins/jenkins:lts
          ports:
            - containerPort: 8080
            - containerPort: 50000
---
apiVersion: v1
kind: Service
metadata:
  name: jenkins
spec:
  type: LoadBalancer
  ports:
    - port: 9090
      targetPort: 8080
  selector:
    app: jenkins
```
* Chạy lệnh sau để triển khai lên kubernetes
```shell
  kubectl apply -f .\jenkins.yaml
```
* Lấy logs của jenkins để tìm mật khẩu admin setup jenkins
```shell
  kubectl logs deployment/jenkins | grep "Please use the following password"
```
* Github: 
  * Chứa source mã nguồn
  * Làm Registry free cho việc đẩy các image docker và package của code
* Docker in docker: [(Cách thức triển khai tại thư mục dind)](/dind)
  * Build và đẩy image lên github registry để có thể lấy được package code và image docker
* Maven: [(Cách thức triển khai tại thư mục maven)](/maven)
  * Triển khai Maven container trong pipeline Jenkins
    * Ưu: 
      * Không cần cài Maven trên server Jenkins
      * Sử dụng đúng phiên bản Maven theo yêu cầu
      * Môi trường build sạch mỗi lần chạy
  * Triển khai tách biệt Maven Container trên K3s
    * Chạy Maven như một service riêng trong K3s