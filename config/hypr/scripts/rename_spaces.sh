#!/usr/bin/env bash

folder="${1:-.}"

while IFS= read -r -d '' f; do
    dir=$(dirname "$f")
    base=$(basename "$f")
    newname="${base// /}"

    if [ "$base" != "$newname" ]; then
        mv -- "$f" "$dir/$newname"
        echo "Archivo: '$base' → '$newname'"
    fi
done < <(find "$folder" -depth -not -type d -print0)
