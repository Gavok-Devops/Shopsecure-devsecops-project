output "waf_acl_arn"        { value = aws_wafv2_web_acl.main.arn }
output "alb_security_group" { value = aws_security_group.alb.id }
