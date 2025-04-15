# #!/bin/bash
# # deploy-devops-lab.sh
# # Tác giả: NguyenNTTSDevOps
# # Version: 1.0
# # Mô tả: Tự động hóa triển khai DevOps Lab environment

# set -e # Dừng script ngay nếu có lỗi

# # --------------------------
# # Cấu hình biến
# # --------------------------
# DOCKER_VERSION="20.10.23"
# COMPOSE_VERSION="v2.20.0"
# PROJECT_DIR="$HOME/devops-lab"
# NETWORK_NAME="devops-net"
# DATA_DIR="$PROJECT_DIR/data"

# # --------------------------
# # Hàm tiện ích
# # --------------------------
# log() {
#   echo -e "\n[$(date +'%Y-%m-%d %H:%M:%S')] >>> $1"
# }

# check_command() {
#   command -v $1 >/dev/null 2>&1 || {
#     log "Lỗi: $1 chưa được cài đặt"
#     exit 1
#   }
# }

# # --------------------------
# # Cài đặt dependencies
# # --------------------------
# install_dependencies() {
#   log "Bắt đầu cài đặt dependencies"
  
#   # Cập nhật package list
#   sudo apt-get update -qq
  
#   # Cài đặt packages cơ bản
#   sudo apt-get install -qq -y \
#     ca-certificates \
#     curl \
#     gnupg \
#     lsb-release \
#     net-tools
  
#   log "Hoàn thành cài đặt dependencies"
# }

# # --------------------------
# # Cài đặt Docker Engine
# # --------------------------
# install_docker() {
#   if ! command -v docker &>/dev/null; then
#     log "Cài đặt Docker Engine..."
    
#     # Thêm Docker GPG key
#     sudo mkdir -p /etc/apt/keyrings
#     curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
#       sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    
#     # Thêm Docker repository
#     echo "deb [arch=$(dpkg --print-architecture) \
#       signed-by=/etc/apt/keyrings/docker.gpg] \
#       https://download.docker.com/linux/ubuntu \
#       $(lsb_release -cs) stable" | \
#       sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
    
#     # Cài đặt Docker
#     sudo apt-get update -qq
#     sudo apt-get install -qq -y \
#       docker-ce=$DOCKER_VERSION \
#       docker-ce-cli=$DOCKER_VERSION \
#       containerd.io \
#       docker-compose-plugin
    
#     # Thêm user vào docker group
#     sudo usermod -aG docker $USER
#     newgrp docker
    
#     log "Docker đã được cài đặt thành công"
#   else
#     log "Docker đã được cài đặt trước đó"
#   fi
# }

# # --------------------------
# # Build custom images
# # --------------------------
# build_custom_images() {
#   log "Bắt đầu build custom images"
  
#   # Build GitLab image
#   docker build -t custom-gitlab:latest -f Dockerfile.gitlab .
  
#   # Build Nginx image
#   docker build -t custom-nginx:latest -f Dockerfile.nginx .
  
#   # Build Nginx Proxy Manager
#   docker build -t custom-nginx-proxy-manager:latest -f Dockerfile.nginx-proxy-manager .
  
#   log "Hoàn thành build custom images"
# }

# # --------------------------
# # Triển khai hệ thống
# # --------------------------
# deploy_system() {
#   log "Khởi tạo Docker network"
#   docker network create --driver overlay $NETWORK_NAME || true
  
#   log "Tạo các volumes và thư mục dữ liệu"
#   mkdir -p $DATA_DIR/{gitlab,nginx-proxy-manager}
#   sudo chmod -R 775 $DATA_DIR
#   sudo chown -R $USER:docker $DATA_DIR
  
#   log "Triển khai Docker stack từ docker-stack.yml"
#   docker stack deploy -c docker-stack.yml devops-stack
  
#   log "Triển khai Docker Compose services"
#   docker compose -f docker-compose.yml up -d
  
#   log "Đang chờ các dịch vụ khởi động..."
#   sleep 30
# }

# # --------------------------
# # Kiểm tra hệ thống
# # --------------------------
# check_services() {
#   log "Kiểm tra trạng thái containers"
#   docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
  
#   log "Kiểm tra network"
#   docker network inspect $NETWORK_NAME
  
#   log "Kiểm tra service ports:"
#   echo -e "GitLab: http://localhost:8080\nPortainer: http://localhost:9443\nNginx Proxy Manager: http://localhost:81"
# }

# # --------------------------
# # Main execution
# # --------------------------
# main() {
#   log "Bắt đầu triển khai DevOps Lab"
  
#   # Kiểm tra thư mục project
#   if [ ! -d "$PROJECT_DIR" ]; then
#     log "Thư mục project không tồn tại! Clone từ Git..."
#     git clone https://github.com/your-repo/devops-lab.git $PROJECT_DIR
#     cd $PROJECT_DIR
#   else
#     cd $PROJECT_DIR
#     git pull origin main
#   fi
  
#   install_dependencies
#   install_docker
#   build_custom_images
#   deploy_system
#   check_services
  
#   log "Triển khai hoàn tất! Truy cập các dịch vụ qua các port đã cấu hình"
# }

# # Chạy main function
# main


#!/bin/bash
# scripts/deploy.sh

set -e

echo "🚀 Starting deployment..."
echo "📦 Copying environment file"
cp .env.sample .env

echo "🐳 Starting Docker services"
install_docker_compose() {
    if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
        log "Cài đặt Docker Compose..."
        sudo curl -L "https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-$(uname -s)-$(uname -m)" \
            -o /usr/local/bin/docker-compose
        sudo chmod +x /usr/local/bin/docker-compose
        sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
    fi
}

run_compose() {
    # Kiểm tra phiên bản Docker Compose
    if docker compose version &> /dev/null; then
        log "Sử dụng Docker Compose V2"
        docker compose up -d --build
    else
        log "Sử dụng Docker Compose V1"
        docker-compose up -d --build
    fi
}

main() {
    log "Bắt đầu triển khai DevOps Lab"
    
    # Kiểm tra và cài đặt Docker
    if ! command -v docker &> /dev/null; then
        install_docker
    fi
    
    # Kiểm tra và cài đặt Docker Compose
    install_docker_compose
    
    # ... (phần còn lại giữ nguyên)
    
    log "🐳 Starting Docker services"
    run_compose
    
    # ... (phần còn lại)
    docker-compose up -d --build

    echo "✅ Deployment completed! Access services:"
    echo "- GitLab: http://localhost:8080"
    echo "- Nginx: http://localhost:8082"
}
