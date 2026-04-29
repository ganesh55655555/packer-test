packer {
  required_plugins {
    amazon = {
      source  = "github.com/hashicorp/amazon"
      version = ">= 1.0.0"
    }
  }
}

source "amazon-ebs" "ubuntu" {
  region        = "ap-south-2"
  instance_type = "t3.micro"
  ssh_username  = "ubuntu"

  ami_name = "demo-ami-{{timestamp}}"

  source_ami_filter {
    filters = {
      name = "ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"
    }
    owners      = ["099720109477"]
    most_recent = true
  }
}

build {
  sources = ["source.amazon-ebs.ubuntu"]

  provisioner "shell" {
    inline = [
      "sudo apt update",
      "sudo apt install -y python3-pip python3-venv",

      "mkdir -p /app",
      "cd /app",

      # create app dynamically
      "echo 'from flask import Flask; app=Flask(__name__); @app.route(\"/\")\\ndef home(): return \"Hello Version BUILD\"' > app.py",

      "echo 'flask\ngunicorn' > requirements.txt",

      "python3 -m venv venv",
      "source venv/bin/activate",
      "pip install -r requirements.txt",

      # create systemd service
      "echo \"[Unit]\nDescription=Demo App\nAfter=network.target\n\n[Service]\nUser=root\nWorkingDirectory=/app\nExecStart=/app/venv/bin/gunicorn --bind 0.0.0.0:80 app:app\nRestart=always\n\n[Install]\nWantedBy=multi-user.target\" > app.service",

      "sudo mv app.service /etc/systemd/system/",
      "sudo systemctl daemon-reexec",
      "sudo systemctl enable app"
    ]
  }
}
