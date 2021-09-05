#!/bin/sh

# clone repos
git clone https://github.com/cse-labs/webvalidate
pushd ./webvalidate/src/app
sed -i 's/api/zzz/' benchmark.json
popd
