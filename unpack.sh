#!/bin/bash

set -e

XIMAGE_FILE="xImage"
UBI_FILE="system.ubi"

quit() {
	echo "Cleaning up ${workdir}..."
	rm -rf "$workdir"
	echo "Done."
	exit 1
}

if [ "$#" -ne 1 ]; then
	 echo "Usage: $0 [file.bin]"
	 exit 1
fi

origdir="$(pwd)"
fwfile="${origdir}/$1"

if [ ! -f "$fwfile" ]; then
	echo "Error: file not found: $1"
	exit 1
fi

workdir="$(mktemp -d)"
cd "$workdir"
echo "Started working on ${workdir}"

trap quit EXIT

echo "Extracting $(basename -- "$fwfile") to $(pwd)..."
tar xf "$fwfile"
echo "Done."

fwfile_gz="$(find . -name "firmware_v[0-1].tar.gz" | head -n 1)"
if [ -z "$fwfile_gz" ]; then
	echo "Error: cannot find firmware_v0|v1.tar.gz in archive"
	quit
fi

echo "Extracting $(basename -- "$fwfile_gz") from $fwfile to $(pwd)..."
tar xf "$fwfile_gz"
echo "Done."

nand_dir="$(pwd)/recovery-update/nand"
if [ ! -d "$nand_dir" ]; then
	echo "Error: cannot find recovery-update/nand directory in $fwfile_gz"
	quit
fi

cd "$nand_dir"

echo "Extracting firmware chunks..."
for file in update0[0-9][0-9].zip; do
	unzip -n "$file" >/dev/null
done
echo "Done."

echo "Generating xImage file..."
cat update0[0-9][0-9]/"$XIMAGE_FILE"_0[0-9][0-9] > "$XIMAGE_FILE"
echo "Done."

echo "Generating UBI image..."
cat update0[0-9][0-9]/"$UBI_FILE"_0[0-9][0-9] > "$UBI_FILE"
echo "Done."

outdirbase="${fwfile}-unpack"
outdir="$outdirbase"
cnt=1
while [ -d "$outdir" ]; do
    outdir="${outdirbase}.${cnt}"
    cnt=$(($cnt+1))
done

echo "Copying extracted files to $outdir..."
mkdir "$outdir"
mv -- */*.xml "$outdir"/
mv "$XIMAGE_FILE" "${outdir}/${XIMAGE_FILE}"
mv "$UBI_FILE" "${outdir}/${UBI_FILE}"
echo "Done."

echo "Bye."
