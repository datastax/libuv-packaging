#!/bin/bash

# sudo apt-get install devscripts automake libtool dh-exec

function check_command {
  command=$1
  package=$2
  if ! type "$command" > /dev/null 2>&1; then
    echo "Missing command '$command', run: apt-get install $package"
    exit 1
  fi
}

check_command "curl" "curl"
check_command "dch" "debhelper"
check_command "lsb_release" "lsb-release"

if [[ -z $1 ]]; then
  echo "Usage: $0 <version> [<arch>]"
  exit 1
fi
version=$1

arch="amd64"
if [[ ! -z $2 ]]; then
  arch=$2
fi

release="1"
dist=$(lsb_release -s -c)
base="libuv-$version"
archive="$base.tar.gz"
url="https://github.com/libuv/libuv/archive/v$version.tar.gz"

if [[ -d build ]]; then
  read -p "Build directory exists, remove? [y|n] " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    rm -rf build
  fi
fi
mkdir -p build

echo "Downloading $archive"
if [[ ! -f "$archive" ]]; then
  curl -Lf --url "$url" --output "build/$archive"
  if [ $? -ne 0 ]; then
    echo "Unable to download archive from $url"
    exit $?
  fi
fi

echo "Extracting $archive"
tar -xf "build/$archive" -C build

pushd "build/$base"
cp -r ../../debian .
echo "Updating changlog"
dch -m -v "$version-$release" -D $dist "Version $version"
echo "Building package:"
debuild -a$arch -i -b -uc -us
popd

exit 0
