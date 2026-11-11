#!/bin/sh
# Native Miyoo Mini Plus controls: B rotates, A jumps, Y opens in-game menu.
cd "$(dirname "$0")" || exit 1
export LD_LIBRARY_PATH="$PWD:/config/lib:/customer/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
mkdir -p save replay/0 replay/1 replay/2

# First-run data only. Never overwrite an existing save or configuration.
for initial in ./miyoo-initial-saves/*; do
    [ -f "$initial" ] || continue
    name=${initial##*/}
    if [ ! -e "save/$name" ]; then
        cp "$initial" "save/$name"
    fi
done

if [ ! -f save/config ] && [ -f ./miyoo-default-config.bin ]; then
    cp ./miyoo-default-config.bin save/config
fi

# The game stores 1024 little-endian 32-bit gameflag integers in save/config.
# gameflag[4] (bytes 16-19) is rotate and gameflag[5] (bytes 20-23) is jump.
# Physical B -> 13; physical A -> 12, per the compiled SDL key mapper.
if [ -f save/config ] && [ -f ./miyoo-control-keys.bin ]; then
    config_bytes=$(wc -c < save/config)
    if [ "$config_bytes" -eq 4096 ]; then
        if [ ! -f save/config.before-miyoo-controls ]; then
            cp save/config save/config.before-miyoo-controls
        fi
        dd if=./miyoo-control-keys.bin of=save/config bs=1 seek=16 conv=notrunc 2>/dev/null || \
            echo "WARNING: unable to set Miyoo controls" >> ./last-launch.log
    else
        echo "WARNING: unexpected save/config length: $config_bytes" >> ./last-launch.log
    fi
fi
exec ./"kaiten" fullscreen >>./last-launch.log 2>&1
