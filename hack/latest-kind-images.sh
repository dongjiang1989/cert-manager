#!/usr/bin/env bash

# Copyright 2022 The cert-manager Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


set -eu -o pipefail

# This script is used to update kind node image digests in the file:
# ./make/kind_images.sh.
#
# Each Kind release is accompanied by a set of compatible "node" images, for a
# range of different Kubernetes versions.
# The digests of these compatible node images are included in the release notes
# on GitHub. They look like:
#  kindest/node:${K8S_VERSION}@sha256:${DIGEST}
#
# This script parses the GitHub release notes, extracts the `kindest/node` image
# references, and saves them to a shell script in the form of environment
# variables so that the script can be sourced by other scripts which pull
# the images and execute `kind`.
# This mechanism is fragile and depends on the Kind release manager using a
# consistent form for the release notes.
# It can be made more robust if / when Kind
# [provide machine-readable list of images for release](https://github.com/kubernetes-sigs/kind/issues/2376).

kind_version=${1:?Supply kind version as first positional argument}

cp ./hack/boilerplate-sh.txt ./make/kind_images.sh.tmp

cat << EOF >> ./make/kind_images.sh.tmp

# generated by "$0 $@" via "make update-kind-images"

EOF

curl -fsSL "https://api.github.com/repos/kubernetes-sigs/kind/releases/tags/${kind_version}" \
    |  jq -r '
[ .body  | capture("- 1\\.(?<minor>[0-9]+): `kindest/node:v(?<version>[^@]+)@sha256:(?<sha256>[^`]+)`\r"; "g") ]
  | sort_by(.minor)
  | .[]
  | "KIND_IMAGE_K8S_1\(.minor)=docker.io/kindest/node@sha256:\(.sha256)"
' >> ./make/kind_images.sh.tmp

chmod +x ./make/kind_images.sh.tmp
mv ./make/kind_images.sh{.tmp,}
