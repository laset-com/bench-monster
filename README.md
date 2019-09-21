# bench-monster

##### Download

`curl -LsO bench.monster/bench.sh; chmod +x bench.sh`

##### Usage

`sh bench.sh` `Arguments` `Parameters (Optional)`

Example: `sh bench.sh -all share`

##### Arguments

`-info` # System Information

`-io` # I/O Test

`-cdn` # CDN Speedtest

`-a` or `-all` # All In One Command

`-b` # System Info + CDN Download + I/O Test

`-na` or `-northamerica` # Benchmark & North America Speedtest

`-naspeed` # North America Speedtest

`-sa` or `-southamerica` # Benchmark & South America Speedtest

`-saspeed` # South America Speedtest

`-eu` or `-europe` # Benchmark & Europe Speedtest

`-euspeed` # Europe Speedtest

`-ua` or `-ukraine` # Benchmark & Ukraine Speedtest

`-uaspeed` # Ukraine Speedtest

`-asia` # Benchmark & Asia/Pacific Speedtest

`-asiaspeed` # Asia/Pacific Speedtest

`-more` # More locations Speedtest

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
