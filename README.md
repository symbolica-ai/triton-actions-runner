# triton-actions-runner
Docker image for a GitHub actions runner, with access to Triton libraries and the Nvidia triton runtime 

Example Usage:

```
docker run --name=triton-runner \
    --env=ACCESS_TOKEN={GH_TOKEN} --env=LABELS=nvidia,ada,docker --env=ORGANIZATION=symbolica-ai --env=REPO_NAME=triton-actions-runner --env=RUNNER_NAME=triton-runner \
    --volume=/var/run/docker.sock:/var/run/docker.sock \
    --restart=always --runtime=nvidia --detach=true \
    ghcr.io/symbolica-ai/triton-actions-runner/runner:latest
```
