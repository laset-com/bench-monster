# bench-monster

##### Download

`curl -LsO bench.monster/bench.sh; chmod +x bench.sh`

##### Usage

`sh bench.sh` `Arguments` `Parameters (Optional)`

Example: `sh bench.sh -all share`

##### Arguments

`-info` # System Information

`-io` # I/O Test

`-cdn` # CDN Speedtest (100MB)

`-a` or `-all` # All In One Command

`-b` # System Info + CDN Download + I/O Test

`-na` or `-northamerica` # Benchmark & North America Speedtest (800MB)

`-naspeed` # North America Speedtest (800MB)

`-sa` or `-southerica` # Benchmark & South America Speedtest (800MB)

`-saspeed` # South America Speedtest (800MB)

`-eu` or `-europe` # Benchmark & Europe Speedtest (900MB)

`-euspeed` # Europe Speedtest (900MB)

`-ua` or `-ukraine` # Benchmark & Ukraine Speedtest (900MB)

`-uaspeed` # Ukraine Speedtest (900MB)

`-asia` # Benchmark & Asia/Pacific Speedtest (400MB)

`-asiaspeed` # Asia/Pacific Speedtest (400MB)

`-more` # More locations Speedtest (400MB)

`-speed` or `-speedtest` # Test from speedtest.net using speedtest cli

`-help` # Show help

`-about` # Show about

##### Parameters

`share`

Example: `sh bench.sh -all share ubuntu`

Available option:

    `ubuntu` # upload results to ubuntu paste

    `haste` # upload results to hastebin

    `clbin` # upload results to clbin (default)


##### _Credits_

Thanks to sayem314 for the the original script.
