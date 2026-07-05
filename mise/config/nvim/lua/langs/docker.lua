-- lua/langs/docker.lua
-- Docker/Dockerfile language support

return {
  filetypes = { "dockerfile" },

  servers = {
    dockerls = {
      cmd = { "docker-langserver", "--stdio" },
    },
    docker_compose_language_service = {
      cmd = { "docker-compose-langserver", "--stdio" },
      filetypes = { "yaml.docker-compose" },
    },
  },

}
