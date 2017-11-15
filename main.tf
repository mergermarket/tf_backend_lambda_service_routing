data "aws_route53_zone" "dns_domain" {
  name = "${data.template_file.domain.rendered}"
}

data "template_file" "domain" {
  template = "$${env == "live" ? "$${domain}" : "dev.$${domain}"}."

  vars {
    env    = "${var.env}"
    domain = "${var.domain}"
  }
}

data "template_file" "fqdn" {
  template = "$${env == "live" ? "$${name}.$${domain}" : "$${env}-$${name}.dev.$${domain}"}"

  vars {
    env = "${var.env}"
    name = "${var.name}"
    domain = "${var.domain}"
  }
}

resource "aws_alb_listener_rule" "rule" {
  listener_arn = "${var.alb_listener_arn}"
  priority     = "${var.priority}"

  action {
    type             = "forward"
    target_group_arn = "${aws_alb_target_group.target_group.arn}"
  }

  condition {
    field  = "host-header"
    values = ["${data.template_file.fqdn.rendered}"]
  }

  condition {
    field  = "path-pattern"
    values = ["*"]
  }
}

resource "aws_alb_target_group" "target_group" {
  name = "${data.template_file.fqdn.rendered}"

  # port will be set dynamically, but for some reason AWS requires a value
  port                 = "31337"
  protocol             = "HTTP"
  vpc_id               = "${var.vpc_id}"
  deregistration_delay = "${var.deregistration_delay}"

  health_check {
    interval            = "${var.health_check_interval}"
    path                = "${var.health_check_path}"
    timeout             = "${var.health_check_timeout}"
    healthy_threshold   = "${var.health_check_healthy_threshold}"
    unhealthy_threshold = "${var.health_check_unhealthy_threshold}"
    matcher             = "${var.health_check_matcher}"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "dns_record" {
  zone_id = "${data.aws_route53_zone.dns_domain.zone_id}"
  name    = "${data.template_file.fqdn.rendered}"

  type    = "CNAME"
  records = ["${var.alb_dns_name}"]
  ttl     = "${var.ttl}"

  depends_on = ["aws_alb_listener_rule", "rule"]
}
