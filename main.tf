data "aws_route53_zone" "dns_domain" {
  name = "${data.template_file.domain.rendered}"
}

data "template_file" "domain" {
  template = "$${env == "live" ? "$${dns_domain}" : "dev.$${dns_domain}"}."

  vars {
    env        = "${var.env}"
    dns_domain = "${var.dns_domain}"
  }
}

data "template_file" "fqdn" {
  template = "$${env == "live" ? "$${name}.$${dns_domain}" : "$${env}-$${name}.dev.$${dns_domain}"}"

  vars {
    env        = "${var.env}"
    name       = "${var.override_dns_name != "" ? var.override_dns_name : replace(var.component_name, "/-service$/", "")}"
    dns_domain = "${var.dns_domain}"
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

locals {
  target_group_name = "${var.env}-${var.component_name}"
  target_group_name_length = "${length(local.target_group_name)}"
  target_group_name_sha1 = "${substr(sha1(local.target_group_name), 0, 8)}"
}

resource "aws_alb_target_group" "target_group" {
  name = "${
    local.target_group_name_length > 32 ?
      join("", list(substr(local.target_group_name, 0, local.target_group_name_length <= 32 ? 0 : 24), local.target_group_name_sha1)) :
      local.target_group_name
  }"

  target_type = "lambda"
}

resource "aws_route53_record" "dns_record" {
  zone_id = "${data.aws_route53_zone.dns_domain.zone_id}"
  name    = "${data.template_file.fqdn.rendered}"

  type    = "CNAME"
  records = ["${var.alb_dns_name}"]
  ttl     = "${var.ttl}"

  depends_on = ["aws_alb_listener_rule.rule"]
}
