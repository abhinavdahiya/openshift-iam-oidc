variable region {
  type = string

}

variable tags {
  type    = map(string)
  default = {}
}

variable infra_id {
  type = string

  description = "An identifier that will be used to make resources names."
}
