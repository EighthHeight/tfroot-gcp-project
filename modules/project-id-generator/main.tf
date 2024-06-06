########
# Project IDs are immutible so it is more flexible to use randomly generated IDs
# This generates a random project id using adjective-animal-4digithex
########

resource "random_pet" "project_id" {
  length    = 2
  separator = "-"
}

resource "random_id" "project_id" {
  prefix      = "${random_pet.project_id.id}-"
  byte_length = 2
}

output "project_id" {
  value = random_id.project_id.hex
}

