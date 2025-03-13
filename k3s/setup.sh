#install master node
curl -sfL https://get.k3s.io K3S_KUBECONFIG_MODE="644" sh -s

#install worker node
curl -sfL https://get.k3s.io | K3S_TOKEN="YOUR_TOKEN" K3S_URL"https://[your_server_id]:6443" K3S_NODE_NAME="servername" sh -

