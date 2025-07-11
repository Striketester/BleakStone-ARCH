#!/bin/bash
set -euo pipefail

source dependencies.sh

if [ -d "$HOME/BYOND/byond/bin" ] && grep -Fxq "${BYOND_MAJOR}.${BYOND_MINOR}" $HOME/BYOND/version.txt;
then
  echo "Using cached directory."
else
  echo "Setting up BYOND, ${BYOND_MAJOR}.${BYOND_MINOR}."
  rm -rf "$HOME/BYOND"
  mkdir -p "$HOME/BYOND"
  cd "$HOME/BYOND"
  curl http://www.byond.com/download/build/516/516.1659_byond_linux.zip -o byond.zip
  unzip byond.zip
  rm byond.zip
  cd byond
  make here
  echo "$BYOND_MAJOR.$BYOND_MINOR" > "$HOME/BYOND/version.txt"
  cd ~/
fi
