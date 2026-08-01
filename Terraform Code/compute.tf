// Data lookup for latest Amazon Linux 2023 AMI
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}

// Declare Launch Template for EC2 instances
resource "aws_launch_template" "conversion_king_lt" {
  name_prefix   = "conversion-king-lt-"
  image_id      = data.aws_ami.amazon_linux_2023.id
  instance_type = "t3.micro"

  vpc_security_group_ids = [aws_security_group.app_ec2_sg.id]

  user_data = base64encode(<<-EOF
            #!/bin/bash
            sudo dnf install -y python3 python3-pip git
            sudo mkdir -p /app && cd /app
            sudo python3 -m venv /app/venv
            sudo /app/venv/bin/pip install --upgrade pip
            sudo /app/venv/bin/pip install flask redis boto3 psycopg2-binary gunicorn

            cat << 'APP_EOF' | sudo tee /app/app.py
            import os
            from flask import Flask, jsonify

            app = Flask(__name__)

            @app.route("/", methods=["GET"])
            def home():
                return jsonify({"service": "Conversion King AI Engine", "status": "healthy", "tier": "EC2 Worker Node"}), 200

            @app.route("/health", methods=["GET"])
            def health_check():
                return "OK", 200

            if __name__ == "__main__":
                app.run(host="0.0.0.0", port=80)
            APP_EOF

            cat << 'SVC_EOF' | sudo tee /etc/systemd/system/conversion-king.service
            [Unit]
            Description=Conversion King AI Flask Service
            After=network.target

            [Service]
            User=root
            WorkingDirectory=/app
            ExecStart=/app/venv/bin/gunicorn --workers 3 --bind 0.0.0.0:80 app:app
            Restart=always
            RestartSec=3

            [Install]
            WantedBy=multi-user.target
            SVC_EOF

            sudo systemctl daemon-reload
            sudo systemctl enable --now conversion-king
            EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "conversion-king-worker-node"
    }
  }
}

// Declare Auto Scaling Group named "conversion-king-asg"
resource "aws_autoscaling_group" "conversion_king_asg" {
  name                = "conversion-king-asg"
  desired_capacity    = 2
  min_size            = 2
  max_size            = 4
  target_group_arns   = [aws_lb_target_group.conversion_king_tg.arn]
  vpc_zone_identifier = [
    aws_subnet.conversion_king_private_subnet.id,
    aws_subnet.conversion_king_private_subnet_2.id
  ]

  launch_template {
    id      = aws_launch_template.conversion_king_lt.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "conversion-king-asg-worker"
    propagate_at_launch = true
  }
}