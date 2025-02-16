set -e

git config --global user.name $GIT_NAME
git config --global user.email $GIT_EMAIL
git config --global safe.directory '*'

bash modules/hyperservice/installer/install.sh

bash .devcontainer/start-network.sh

bash modules/hyperservice/fleet/simulate-remote/build-image.sh
bash .devcontainer/start-base-fleet.sh

hy mesh up