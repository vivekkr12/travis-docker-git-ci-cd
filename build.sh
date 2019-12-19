#!/bin/bash -e

install() {
  python -m pip install --upgrade pip
  pip install wheel
  cd app
  npm install
  cd ..
  cd api
  pip install -r requirements.txt
  cd ..
  exit 0
}

package() {
  cd app
  npm run lint
  npm run build
  cd ..
  cd api
  python setup.py bdist_wheel
  cd ..
  exit 0
}

update_version() {
  echo "This is update version"
}

deploy() {
  docker build -t travis-docker-git-ci-cd:"$TRAVIS_COMMIT" .
}

if [ $# -eq 0 ]
  then
    echo "no command line argument passed, required one of: install | package | deploy"
    exit 1
fi

action=$1
if [ "$action" = "install" ]; then
  install
elif [ "$action" = "package" ]; then
  package
elif [ "$action" = "deploy" ]; then
  deploy
else
  echo "invalid command line argument $action, required one of install | package | deploy"
  exit 1
fi
