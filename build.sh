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

setup_config() {
  # setup git
  git config --global user.email "fake@travis-bot"
  git config --global user.name "Travis CI Bot"

  git remote set-url origin git@github.com:vivekkr12/travis-docker-git-ci-cd.git
  echo "$TRAVIS_DEPLOY_KEY" > "$HOME"/.ssh/id_rsa
  echo "github.com ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAq2A7hRGmdnm9tUDbO9IDSwBK6TbQa+PXYPCPy6rbTrTtw7PHkccKrpp0yVhp5HdEIcKr6pLlVDBfOLX9QUsyCOV0wzfjIJNlGEYsdlLJizHhbn2mUjvSAHQqZETYP81eFzLQNnPHt4EVVUh7VfDESU84KezmD5QlWpXLmvU31/yMf+Se8xhHTvKSCZIFImWwoG6mbUoWf9nzpIoaSjB+weqqUUmpaaasXVal72J+UX2B+2RPW3RcT0eOzQgqlJL3RKrTJvdsjE3JEAvGq3lGHSZXy28G3skua2SmVi/w4yCE6gbODqnTWlg7+wC604ydGXA8VJiS5ap43JXiUFFAaQ==" > "$HOME"/.ssh/known_hosts

  # setup docker
  echo "$TRAVIS_DOCKER_PASSWORD" | docker login -u "$TRAVIS_DOCKER_USERNAME" --password-stdin
}

update_version() {
  # get the version bump part from commit message
  TRAVIS_COMMIT_MESSAGE="Merge pull request #88 from OutdoorRD/misc #release=minor"
  release_part=$(echo "$TRAVIS_COMMIT_MESSAGE" | awk -F# '{print $NF}' | awk -F= '{print $1}')
  if [ "$release_part" = "release" ]; then
      version_part=$(echo "$TRAVIS_COMMIT_MESSAGE" | awk -F# '{print $NF}' | awk -F= '{print $2}')
      if [ "$version_part" = "major" ]; then
        version_bump="major"
      elif [ "$version_part" = "minor" ]; then
        version_bump="minor"
      elif [ "$version_part" = "patch" ]; then
        version_bump="patch"
      else
        version_bump="patch"
      fi
  else
    version_bump="patch"
  fi

  # update the version in package.json as it's the easiest thing to do using npm
  cd app
  new_version=$(npm version $version_bump)  # this returs the new versio number with 'v' as prefix
  new_version=$(echo "$new_version" | awk -Fv '{print $2}')
  cd ..
  cd api
  sed -i "s/__version__.*/__version__ = '$new_version'/" api/__init__.py
  cd ..
  echo "local version bump successful"

  git commit -m "update version to $new_version, travis build: $TRAVIS_BUILD_NUMBER"

}

deploy() {
  setup_git
  update_version
  docker build -t travis-docker-git-ci-cd:"$TRAVIS_COMMIT" .
  new_version=$(npm view app version)

  git tag v"$new_version"
  git push origin master
  git push origin --tags

  docker tag travis-docker-git-ci-cd:"$TRAVIS_COMMIT" vivekkr12/travis-docker-git-ci-cd:"$TRAVIS_COMMIT"
  docker tag travis-docker-git-ci-cd:"$TRAVIS_COMMIT" vivekkr12/travis-docker-git-ci-cd:"$new_version"
  docker tag travis-docker-git-ci-cd:"$TRAVIS_COMMIT" vivekkr12/travis-docker-git-ci-cd:latest

  docker push vivekkr12/travis-docker-git-ci-cd:"$TRAVIS_COMMIT"
  docker push vivekkr12/travis-docker-git-ci-cd:"$new_version"
  docker push vivekkr12/travis-docker-git-ci-cd:latest
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
