#!/bin/sh

# clone repos
git clone https://github.com/retaildevcrews/loderunner
pushd ./loderunner
sed -i 's/api/zzz/' benchmark.json
popd

# install webv
dotnet tool install -g webvalidate --version 2.0.0-beta2
