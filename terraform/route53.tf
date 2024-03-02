resource "aws_route53_zone" "personal_domain" {
  name = "sethltaylor.dev"
}

resource "aws_route53_record" "bird_tracker_record" {
    zone_id = aws_route53_zone.personal_domain.zone_id
    name = "bird-sightings.sethltaylor.dev"
    type = "CNAME"
    ttl = "300"
    records = [aws_alb.ecs_alb.dns_name]
}