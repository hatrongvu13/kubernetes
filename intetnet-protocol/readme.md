# Internet protocol
## Custome image from github
Để có thể lấy được image từ github registry cần cấu hình secrets chứa thông tin đăng nhập để truy cập vào github registry
```shell
#secret
kubectl create secret docker-registry ghcr-secret \
  --docker-server=ghcr.io \
  --docker-username=your-github-username \
  --docker-password=your-new-token \
  --docker-email=your-email@example.com \
  --namespace=default
```
Với: 
* `kubectl create secret docker-registry`: Tạo một Kubernetes Secret kiểu docker-registry, dùng để lưu thông tin xác thực Docker
* `ghcr-secret`: Tên của Secret sẽ được tạo
* `--docker-server=ghcr.io`: Địa chỉ của container registry, ở đây là GitHub Container Registry (GHCR).
* `--docker-username=your-github-username`: Tên người dùng GitHub của bạn.
* `--docker-password=your-new-token`: Token truy cập GitHub (không phải mật khẩu tài khoản GitHub).
* `--docker-email=your-email@example.com`: Email của bạn (bắt buộc nhưng Kubernetes không sử dụng giá trị này).
* `--namespace=default`: Tạo Secret trong namespace mặc định.

Cách sử dụng: Tham chiếu tới nó với `imagePullSecrets` 
Ví dụ:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: my-pod
spec:
  containers:
    - name: my-container
      image: ghcr.io/your-github-username/your-image:latest
  imagePullSecrets:
    - name: ghcr-secret
```


