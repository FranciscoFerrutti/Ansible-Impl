variable "name" {
    type = string
}

variable "handler" {
    type = string
}

variable "method" {
    type = string
}

variable "api_folder" {
    type = string
}

variable "env_vars" {
    type = map(string)
    default = {}
}