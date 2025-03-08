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

