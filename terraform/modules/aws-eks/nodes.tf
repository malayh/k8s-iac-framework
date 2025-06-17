resource "aws_iam_role" "nodes" {
  name = "${local.cluster_name}-node-role"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy_attachment" "nodes-AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.nodes.name
}

resource "aws_iam_role_policy_attachment" "nodes-AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.nodes.name
}

resource "aws_iam_role_policy_attachment" "nodes-AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.nodes.name
}
resource "aws_iam_role_policy_attachment" "nodes-AmazonEBSCSIDriverPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  role       = aws_iam_role.nodes.name
}

resource "aws_security_group" "eks_nodes_sg" {
  vpc_id      = var.vpc_id
  name_prefix = "${local.cluster_name}-nodes-sg-"
}

resource "aws_security_group_rule" "ingress" {
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.eks_nodes_sg.id
  cidr_blocks       = [var.vpc_cidr_block]
}

resource "aws_security_group_rule" "egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.eks_nodes_sg.id
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_launch_template" "launch_template" {
  name = "${local.cluster_name}-launch-template"

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 3
    instance_metadata_tags      = "enabled"
  }
  vpc_security_group_ids = [aws_security_group.eks_nodes_sg.id, aws_eks_cluster.main.vpc_config[0].cluster_security_group_id]

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${local.cluster_name}-node"
    }
  }
}

resource "aws_eks_node_group" "node_groups" {
  for_each = var.node_groups

  cluster_name    = aws_eks_cluster.main.name
  node_group_name = each.key
  node_role_arn   = aws_iam_role.nodes.arn
  subnet_ids      = var.private_subnet_ids
  instance_types  = ["${each.value.instance_type}"]


  scaling_config {
    desired_size = each.value.count
    max_size     = each.value.count + 1
    min_size     = max(each.value.count - 1, 1)
  }

  dynamic "taint" {
    for_each = each.value.taint
    content {
      key    = taint.value.key
      value  = taint.value.value
      effect = taint.value.effect
    }
  }



  update_config {
    max_unavailable = 1
  }

  launch_template {
    id      = aws_launch_template.launch_template.id
    version = "1"
  }


  depends_on = [
    aws_eks_cluster.main,
    aws_iam_role_policy_attachment.nodes-AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.nodes-AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.nodes-AmazonEC2ContainerRegistryReadOnly,
    aws_iam_role_policy_attachment.nodes-AmazonEBSCSIDriverPolicy
  ]

  lifecycle {
    ignore_changes = [launch_template]
  }
}