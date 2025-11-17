#!/bin/sh
set -e

# This script downloads the binaries for the most recent version of NeoAi.

version="$(curl -sS https://update.neoai.com/bundles/version)"
targets='i686-pc-windows-gnu
    x86_64-apple-darwin
    x86_64-pc-windows-gnu
    x86_64-unknown-linux-musl
    aarch64-apple-darwin'

rm -rf ./binaries

echo "$targets" | while read target
do
    mkdir -p binaries/$version/$target
    path=$version/$target
    echo "downloading $path"
    curl -sS https://update.neoai.com/bundles/$path/NeoAi.zip > binaries/$path/NeoAi.zip
    unzip -o binaries/$path/NeoAi.zip -d binaries/$path
    rm binaries/$path/NeoAi.zip
    chmod +x binaries/$path/*
done

binariesver=$(grep -Eo '!binaries/.*' .gitignore | cut -c10-)
sed "s+$binariesver+/$version+g" .gitignore >.gitignore.tmp && mv .gitignore.tmp .gitignore