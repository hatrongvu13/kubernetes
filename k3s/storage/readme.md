# Cấu hình thêm lưu trữ ngoài cho K3s
## Sử dụng một ổ cứng ngoài gắn vào một node làm nơi lưu trữ
### Sử dụng một local storage
* Mount ổ cứng vào làm local storage
    * Sử dụng lệnh để lấy danh sách ổ cứng ngoài được sử dụng
```shell
    lsblk  
```
* Tạo thư mục để mount ổ cứng ngoài (nếu chưa có)
```shell
mkdir [path_new_folder]
#ex
mkdir /mnt/data
```
* Mount ổ cứng ngoài với thư mục
```shell
sudo mount [path_to_disk] [path_to_folder]
#ex
sudo mount /dev/sda /mnt/data
```
* Thêm các quyền đọc ghi
```shell
sudo chmod -R 775 /mnt/data
sudo chown -R 1000:1000 /mnt/data
```
* File triển khai local storage
```yaml 
apiVersion: v1
kind: PersistentVolume
metadata:
  name: local-pv
spec:
  capacity:
    storage: 50Gi  # Dung lượng ổ cứng
  volumeMode: Filesystem
  accessModes:
    - ReadWriteOnce  # Có thể chỉnh thành ReadWriteMany nếu cần
  persistentVolumeReclaimPolicy: Retain
  storageClassName: manual # Tên của StorageClass PV (*)
  local:
    path: /mnt/disks/storage  # Đường dẫn đến ổ cứng được mount
  nodeAffinity:
    required:
      nodeSelectorTerms:
        - matchExpressions:
            - key: kubernetes.io/hostname
              operator: In
              values:
                - <node-name>  # Tên của node mà ổ cứng đã được gắn vào 
```
### Sử dụng 
* Tạo một Persistent Volume Claim (PVC)
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: local-pvc # Tên của PVC
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 50Gi  # Chỉ định dung lượng bạn muốn yêu cầu
  storageClassName: manual  # Tên StorageClass cần trùng với PV
```
# Tạo NFS Server
## Mount ổ cứng vừa gắn vào 1 đường dẫn ví dụ: mnt/data
```shell
sudo mount /dev/sdb1 /mnt/data
```

sau đó triển khai nfs server với:
```shell
sudp apt update
sudo apt install -y nfs-kernel-server
```
Kiểm tra và cấp quyền truy cập cho thư mục vừa mount ổ cứng [/mnt/data]
```shell
sudo mkdir -p /mnt/data
sudo chown -R nobody:nogroup /mnt/data
sudo chmod -R 777 /mnt/data
```
Chỉnh sửa file /etc/exports để chia sẻ thư mục này
```shell
echo "/mnt/data *(rw,sync,no_subtree_check,no_root_squash)" | sudo tee -a /etc/exports
```
với :
* mnt/data: đường đẫn tới thư mục chia sẻ
* *(rw,sync,no_subtree_check,no_root_squash)": 
  * "*": có nghĩa là cho phép mọi client truy cập giới hạn lại bằng cách điền ip hoặc dải ip cụ thể ví dụ : 192.168.1.0/24
  * rw: cho phép đọc ghi
  * no_subtree_check: bỏ qua kiểm tra quyền truy cập ở thư mục con
  * no_root_squash: cho phép truy cập thư mục với quyền root 
  * sudo tee -a /etc/exports: ghi thêm vào tệp /etc/exports mà không ghi đè
### [Optional] Cài đặt nfs-subdir-external-provisioner để tự động tạo PV trong K3s
Triển khai quyền RBAC 
```yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/nfs-subdir-external-provisioner/master/deploy/rbac.yaml
```

### Tạo file nfs-provisioner.yaml với nội dung sau để triển khai NFS Provisioner :
```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: nfs-provisioner

---
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: nfs-storage
provisioner: example.com/nfs
reclaimPolicy: Retain
parameters:
  archiveOnDelete: "false"

---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: nfs-client-provisioner
  namespace: nfs-provisioner

---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nfs-client-provisioner
  namespace: nfs-provisioner
spec:
  replicas: 1
  selector:
    matchLabels:
      app: nfs-client-provisioner
  template:
    metadata:
      labels:
        app: nfs-client-provisioner
    spec:
      serviceAccountName: nfs-client-provisioner
      containers:
        - name: nfs-client-provisioner
          image: quay.io/external_storage/nfs-client-provisioner:latest
          volumeMounts:
            - mountPath: /persistentvolumes
              name: nfs-volume
          env:
            - name: PROVISIONER_NAME
              value: "example.com/nfs"
            - name: NFS_SERVER
              value: "192.168.1.1"
            - name: NFS_PATH
              value: "/mnt/data/k3s"
      volumes:
        - name: nfs-volume
          nfs:
            server: "192.168.1.1"
            path: "/mnt/data/k3s"
```
Triển khai role cho nfs
```yaml

apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: nfs-client-provisioner-role
  namespace: nfs-provisioner
rules:
  - apiGroups: [""]
    resources: ["endpoints"]
    verbs: ["get", "list", "watch", "create", "update", "patch"]
  - apiGroups: [""]
    resources: ["persistentvolumeclaims"]
    verbs: ["get", "list", "watch", "create", "update", "patch"]
  - apiGroups: [""]
    resources: ["persistentvolumes"]
    verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
```
role bindding
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: nfs-client-provisioner-binding
  namespace: nfs-provisioner
subjects:
  - kind: ServiceAccount
    name: nfs-client-provisioner
    namespace: nfs-provisioner
roleRef:
  kind: Role
  name: nfs-client-provisioner-role
  apiGroup: rbac.authorization.k8s.io
```
cluster role -> cluster role binding