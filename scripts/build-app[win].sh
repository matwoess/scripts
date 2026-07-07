#!/bin/bash

confirm () {
  # call with a prompt string or use a default
  read -n1 -r -p "${1:-$1} " response
  echo ""
  case $response in
    [yY][eE][sS]|[yY]) true ;;
    *) false ;;
  esac
}

promptversion () {
  read -r -p "${1:-$1} " version
  echo "filename: velocity_v$version.apk"
}

updatesource () {
  echo ":: updating the project"
  cd D:
  cd temp/project/default/
  git pull
}

buildandcopy () {
  echo ":: building the apk"
  cd D:
  cd temp/project/default/
  ./gradlew aR
  echo ":: copying to Downloads"
  promptversion "version number?: "
  [ -f app/build/outputs/apk/app-debug.apk ] && cp app/build/outputs/apk/app-debug.apk ~/Downloads/velocity_v$version.apk
}

confirm "update sources? [y/N]" && updatesource
confirm "build the apk? [y/N]" && buildandcopy
echo "[  DONE  ]"
echo "Press return to exit..."
read
