# build.ps1 - Build the Docker image (and optionally push to Docker Hub)
docker compose build --progress=plain
if ($env:PUSH_IMAGE -eq "1") {
  docker push alexandrewsai/simple-agent-sandbox:latest
}
