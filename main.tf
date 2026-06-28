provider "aws" {
  region = "ap-south-1" # Change to your preferred region
}

# 1. Create a Security Group for the Kubernetes Node
resource "aws_security_group" "k8s_sg" {
  name        = "k8s-node-sg"
  description = "Security group for Kubernetes EC2 node"

  # SSH Access
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Restrict this to your IP in production!
  }

  # Kubernetes API Server (Required for Control Plane)
  ingress {
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Kubelet API, Etcd, Calico/Flannel (Internal Cluster Communication)
  ingress {
    from_port   = 10250
    to_port     = 10255
    protocol    = "tcp"
    self        = true
  }

  # Outbound Internet Access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 2. Launch the EC2 Instance
resource "aws_instance" "k8s_node" {
  ami           = "ami-01a00762f46d584a1" # Ubuntu 24.04 LTS AMI for ap-south-1 (Update per region)
  instance_type = "t3.medium"             # Minimum requirement for K8s

  # key_name               = "your-aws-key-pair" # Replace with your existing AWS SSH Key pair name
  key_name               = "ssh-key-pair" # Replace with your existing AWS SSH Key pair name
  vpc_security_group_ids = [aws_security_group.k8s_sg.id]

  # Allocate enough storage for containers
  root_block_device {
    volume_size = 30
    volume_type = "gp3"
  }

  # Bootstrap Kubernetes prerequisites using user_data
  user_data = file("bootstrap.sh")

  tags = {
    Name = "k8s-control-plane"
  }
}

output "instance_public_ip" {
  value = aws_instance.k8s_node.public_ip
}