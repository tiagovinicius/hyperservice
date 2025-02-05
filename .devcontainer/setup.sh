git config --global user.name $GIT_NAME
git config --global user.email $GIT_EMAIL
git config --global --add safe.directory /workspace

bash modules/hyperservice/installer/install.sh
bash modules/hyperservice/fleet/simulate-remote/build-image.sh
bash .devcontainer/start-fleet-unit-x.sh