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
* Hoặc có thể vào trực tiếp xem log của pod jenkins khi sử dụng lens để điểu khiển k3s cluster
* Github: 
  * Chứa source mã nguồn
  * Làm Registry free cho việc đẩy các image docker và package của code
* Docker in docker: [(Cách thức triển khai tại thư mục dind)](/dind)
  * Build và đẩy image lên github registry để có thể lấy được package code và image docker
  * Trong Jenkins:
    * 1 Vào Manage Jenkins → Manage Plugins → Install "Docker Pipeline".
    * 2 Vào Manage Jenkins → Manage Nodes and Clouds → Configure Clouds → Add New Cloud → Docker.
    * 3 Điền URL của Docker Daemon (DinD Service):
    ``` groovy
      tcp://dind:2375
    ```
    * 4 Bật "Expose DOCKER_HOST environment variable".
    * 5 Lưu lại và restart Jenkins.
  * Kiểm tra Dind trêb Jenkins
```groovy
pipeline {
  agent any
  environment {
    DOCKER_HOST = "tcp://dind:2375"
  }
  stages {
    stage('Check User & Install Docker CLI') {
      steps {
        sh '''
                if ! command -v docker &> /dev/null; then
                    echo "Installing Docker CLI..."
                    apt update && apt install -y docker.io || echo "Failed to install Docker CLI"
                else
                    echo "Docker CLI is already installed."
                fi
                '''
      }
    }
    stage('Test Docker') {
      steps {
        sh 'docker version'
        sh 'docker info'
        sh 'docker run hello-world'
      }
    }
  }
}
```
* Maven: [(Cách thức triển khai tại thư mục maven)](/maven)
  * Triển khai Maven container trong pipeline Jenkins
    * Ưu: 
      * Không cần cài Maven trên server Jenkins
      * Sử dụng đúng phiên bản Maven theo yêu cầu
      * Môi trường build sạch mỗi lần chạy
  * Triển khai tách biệt Maven Container trên K3s
    * Chạy Maven như một service riêng trong K3s