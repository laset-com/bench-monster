#!/bin/bash

# shellcheck disable=SC1117,SC2086,SC2003,SC1001,SC2116,SC2046,2128,2124

about () {
	echo ""
	echo "  ========================================================= "
	echo "  \        Bench.Monster - Server Benchmark Script        / "
	echo "  \       Basic system info, I/O test and speedtest       / "
	echo "  \               V 1.3.1 beta  (29 Sep 2019)             / "
	echo "  \       https://github.com/laset-com/bench-monster      / "
	echo "  \                  https://bench.monster                / "
	echo "  ========================================================= "
	echo ""
}

prms () {
	echo "  Arguments:"
	echo "    $(tput setaf 3)-info$(tput sgr0)      - Check basic system information"
	echo "    $(tput setaf 3)-io$(tput sgr0)        - Run I/O test with or w/ cache"
	echo "    $(tput setaf 3)-cdn$(tput sgr0)       - Check download speed from CDN"
	echo "    $(tput setaf 3)-na$(tput sgr0)        - Benchmark & Speedtest from North America"
	echo "    $(tput setaf 3)-naspeed$(tput sgr0)   - Speedtest from North America"
	echo "    $(tput setaf 3)-sa$(tput sgr0)        - Benchmark & Speedtest from South America"
	echo "    $(tput setaf 3)-saspeed$(tput sgr0)   - Speedtest from South America"
	echo "    $(tput setaf 3)-eu$(tput sgr0)        - Benchmark & Speedtest from Europe"
	echo "    $(tput setaf 3)-euspeed$(tput sgr0)   - Speedtest from Europe"
	echo "    $(tput setaf 3)-ua$(tput sgr0)        - Benchmark & Speedtest from Ukraine"
	echo "    $(tput setaf 3)-uaspeed$(tput sgr0)   - Speedtest from Ukraine"
	echo "    $(tput setaf 3)-asia$(tput sgr0)      - Benchmark & Speedtest from Asia"
	echo "    $(tput setaf 3)-asiaspeed$(tput sgr0) - Speedtest from Asia"
	echo "    $(tput setaf 3)-more$(tput sgr0)      - Speedtest from more locations"
	echo "    $(tput setaf 3)-a$(tput sgr0)         - Test and check all above things at once"
	echo "    $(tput setaf 3)-b$(tput sgr0)         - System info, CDN speedtest and I/O test"
	echo "    $(tput setaf 3)-speed$(tput sgr0)     - Check internet speed using speedtest-cli"
	echo "    $(tput setaf 3)-about$(tput sgr0)     - Check about this script"
	echo ""
	echo "  Parameters"
	echo "    $(tput setaf 3)share$(tput sgr0)         - upload results (default to clbin)"
	echo "    Available option for share:"
	echo "      clbin # upload results to clbin (default)"
	echo "      ubuntu # upload results to paste.ubuntu"
	echo "      haste # upload results to hastebin"
}

howto () {
	echo ""
	echo "  Wrong parameters. Use $(tput setaf 3)bash $BASH_SOURCE -help$(tput sgr0) to see parameters"
	echo "  ex: $(tput setaf 3)bash $BASH_SOURCE -info$(tput sgr0) (without quotes) for system information"
	echo ""
}

benchinit() {
	if ! hash curl 2>$NULL; then
		echo "missing dependency curl"
		echo "please install curl first"
		exit
	fi

echo "=================================================" | tee -a $log
echo "  Bench.Monster v1.3.1 -> https://bench.monster" | tee -a $log
benchstart=$(date +"%d-%b-%Y %H:%M:%S")
	start_seconds=$(date +%s)
echo "  Benchmark timestamp:    $benchstart" | tee -a $log
echo "=================================================" | tee -a $log

echo "" | tee -a $log
}

CMD="$1"
PRM1="$2"
PRM2="$3"
log="$HOME/benchmonster.log"
ARG="$BASH_SOURCE $@"
benchram="/mnt/tmpbenchram"
NULL="/dev/null"
true > $log

cancel () {
	echo ""
	rm -f test
	echo " Abort"
	if [[ -d $benchram ]]; then
		rm $benchram/zero
		umount $benchram
		rm -rf $benchram
	fi
	exit
}

trap cancel SIGINT

systeminfo () {
	# Systeminfo
	echo "" | tee -a $log
	echo " $(tput setaf 6)## System Information$(tput sgr0)"
	echo " ## System Information" >> $log
	echo "" | tee -a $log

	# OS Information (Name)
	cpubits=$( uname -m )
	if echo $cpubits | grep -q 64; then
		bits=" (64 bit)"
	elif echo $cpubits | grep -q 86; then
		bits=" (32 bit)"
	elif echo $cpubits | grep -q armv5; then
		bits=" (armv5)"
	elif echo $cpubits | grep -q armv6l; then
		bits=" (armv6l)"
	elif echo $cpubits | grep -q armv7l; then
		bits=" (armv7l)"
	else
		bits="unknown"
	fi

	if hash lsb_release 2>$NULL; then
		soalt=$(lsb_release -d)
		echo -e " OS Name     : "${soalt:13} $bits | tee -a $log
	else
		so=$(awk 'NF' /etc/issue)
		pos=$(expr index "$so" 123456789)
		so=${so/\/}
		extra=""
		if [[ "$so" == Debian*10* ]]; then
			extra="(Buster)"
		elif [[ "$so" == Debian*9* ]]; then
			extra="(Stretch)"
		elif [[ "$so" == Debian*8* ]]; then
			extra="(Jessie)"
		elif [[ "$so" == Debian*7* ]]; then
			extra="(Wheezy)"
		elif [[ "$so" == Debian*6* ]]; then
			extra="(Squeeze)"
		fi
		if [[ "$so" == *Proxmox* ]]; then
			so="Debian 7.6 (Wheezy)";
		fi
		otro=$(expr index "$so" \S)
		if [[ "$otro" == 2 ]]; then
			so=$(cat /etc/*-release)
			pos=$(expr index "$so" NAME)
			pos=$((pos-2))
			so=${so/\/}
		fi
		echo -e " OS Name     : "${so:0:($pos+2)}$extra$bits | tr -d '\n' | tee -a $log
		echo "" | tee -a $log
	fi
	sleep 0.1

	#Detect virtualization
	if hash ifconfig 2>/dev/null; then
		eth=$(ifconfig)
	fi

	virtualx=$(dmesg) 2>/dev/null
	
	if grep docker /proc/1/cgroup -qa; then
	    virtual="Docker"
	elif grep lxc /proc/1/cgroup -qa; then
		virtual="LXC"
	elif grep -qa container=lxc /proc/1/environ; then
		virtual="LXC"
	elif [[ -f /proc/user_beancounters ]]; then
		virtual="OpenVZ"
	elif [[ "$virtualx" == *kvm-clock* ]]; then
		virtual="KVM"
	elif [[ "$cname" == *KVM* ]]; then
		virtual="KVM"
	elif [[ "$virtualx" == *"VMware Virtual Platform"* ]]; then
		virtual="VMware"
	elif [[ "$virtualx" == *"Parallels Software International"* ]]; then
		virtual="Parallels"
	elif [[ "$virtualx" == *VirtualBox* ]]; then
		virtual="VirtualBox"
	elif [[ -e /proc/xen ]]; then
		virtual="Xen"
	elif [[ "$sys_manu" == *"Microsoft Corporation"* ]]; then
		if [[ "$sys_product" == *"Virtual Machine"* ]]; then
			if [[ "$sys_ver" == *"7.0"* || "$sys_ver" == *"Hyper-V" ]]; then
				virtual="Hyper-V"
			else
				virtual="Microsoft Virtual Machine"
			fi
		fi
	else
		virtual="Dedicated"
	fi

	#Kernel
	echo " Kernel      : $virtual / $(uname -r)" | tee -a $log
	sleep 0.1

	# Hostname
	#echo " Hostname    : $(hostname)" | tee -a $log
	#sleep 0.1

	# CPU Model Name
	cpumodel=$( awk -F: '/model name/ {name=$2} END {print name}' /proc/cpuinfo )
	echo " CPU Model   :$cpumodel" | tee -a $log
	sleep 0.1

	# CPU Cores
	cores=$( awk -F: '/model name/ {core++} END {print core}' /proc/cpuinfo )
	corescache=$( awk -F: '/cache size/ {cache=$2} END {print cache}' /proc/cpuinfo )
	freq=$( awk -F: ' /cpu MHz/ {freq=$2} END {print freq}' /proc/cpuinfo )
	if [[ $cores == "1" ]]; then
		echo " CPU Cores   : $cores core @ $freq MHz $corescache cache" | tee -a $log
	else
		echo " CPU Cores   : $cores cores @ $freq MHz $corescache cache" | tee -a $log
	fi
	sleep 0.1
	load=$( w | head -1 | awk -F'load average:' '{print $2}' | sed 's/^[ \t]*//;s/[ \t]*$//' )
	echo " Load average: $load" | tee -a $log
	sleep 0.1

	# RAM Information
	tram="$( free -m | grep Mem | awk 'NR=1 {print $2}' ) MiB"
	fram="$( free -m | grep Mem | awk 'NR=1 {print $7}' ) MiB"
	fswap="$( free -m | grep Swap | awk 'NR=1 {print $4}') MiB"
	echo " Total RAM   : $tram (Free $fram)" | tee -a $log
	sleep 0.1

	# Swap Information
	tswap="$( free -m | grep Swap | awk 'NR=1 {print $2}' ) MiB"
	tswap0=$( grep SwapTotal < /proc/meminfo | awk 'NR=1 {print $2$3}' )
	if [[ "$tswap0" == "0kB" ]]; then
		echo " Total SWAP  : SWAP not enabled" | tee -a $log
	else
		echo " Total SWAP  : $tswap (Free $fswap)" | tee -a $log
	fi
	sleep 0.1

	# HDD information
	hdd=$( df -h --total --local -x tmpfs | grep 'total' | awk '{print $2}' )B
	hddfree=$( df -h --total | grep 'total' | awk '{print $5}' )
	echo " Total Space : $hdd ($hddfree used)" | tee -a $log
	sleep 0.1

	# Uptime
	secs=$( awk '{print $1}' /proc/uptime | cut -f1 -d"." )
	if [[ $secs -lt 120 ]]; then
		sysuptime="$secs seconds"
	elif [[ $secs -lt 3600 ]]; then
		sysuptime=$( printf '%d minutes %d seconds\n' $((secs%3600/60)) $((secs%60)) )
	elif [[ $secs -lt 86400 ]]; then
		sysuptime=$( printf '%d hrs %d min %d sec\n' $((secs/3600)) $((secs%3600/60)) $((secs%60)) )
	else
		sysuptime=$( echo $((secs/86400))" days - "$(date -d "1970-01-01 + $secs seconds" "+%H hrs %M min %S sec") )
	fi
	echo " Running for : $sysuptime" | tee -a $log
	echo "" | tee -a $log
}

echostyle(){
	if hash tput 2>$NULL; then
		echo " $(tput setaf 6)$1$(tput sgr0)"
		echo " $1" >> $log
	else
		echo " $1" | tee -a $log
	fi
}

FormatBytes() {
	bytes=${1%.*}
	local Mbps=$( printf "%s" "$bytes" | awk '{ printf "%.2f", $0 / 1024 / 1024 * 8 } END { if (NR == 0) { print "error" } }' )
	if [[ $bytes -lt 1000 ]]; then
		printf "%8i B/s |      N/A    "  $bytes
	elif [[ $bytes -lt 1000000 ]]; then
		local KiBs=$( printf "%s" "$bytes" | awk '{ printf "%.2f", $0 / 1024 } END { if (NR == 0) { print "error" } }' )
		printf "%7s KB/s | %7s Mbps" "$KiBs" "$Mbps"
	else
		# awk way for accuracy
		local MiBs=$( printf "%s" "$bytes" | awk '{ printf "%.2f", $0 / 1024 / 1024 } END { if (NR == 0) { print "error" } }' )
		printf "%7s MB/s | %7s Mbps" "$MiBs" "$Mbps"

		# bash way
		# printf "%4s MiB/s | %4s Mbps""$(( bytes / 1024 / 1024 ))" "$(( bytes / 1024 / 1024 * 8 ))"
	fi
}

pingtest() {
	# ping one time
	local ping_link=$( echo ${1#*//} | cut -d"/" -f1 )
	local ping_ms=$( ping -w 1 -c 1 -q $ping_link | cut -d "/" -s -f5 )

	# get download speed and print
	if [[ $ping_ms == "" ]]; then
		printf " | ping error!"
	else
		printf " | ping %3i.%sms" "${ping_ms%.*}" "${ping_ms#*.}"
	fi
}

# main function for speed checking
# the report speed are average per file
speed() {
	# print name
	printf "%s" " $1" | tee -a $log

	# get download speed and print
	C_DL=$( curl -4 -m 9 -w '%{speed_download}\n' -o $NULL -s "$2" )
	printf "%s\n" "$(FormatBytes $C_DL) $(pingtest $2)" | tee -a $log
}

# 1 location (100MB)
cdnspeedtest () {
	echo "" | tee -a $log
	echostyle "## CDN Speedtest"
	echo "" | tee -a $log
	speed "CacheFly :" "http://cachefly.cachefly.net/100mb.test"
	echo ""
}

# 10 location (1GB)
northamericaspeedtest () {
	echo "" | tee -a $log
	echostyle "## North America Speedtest"
	echo "" | tee -a $log
	speed "USA, New York (DigitalOcean) :" "http://speedtest-nyc3.digitalocean.com/100mb.test"
	speed "USA, Washington D.C. (Psychz):" "http://ash.lg.budgetnode.net/100MB.test"
	speed "USA, Chicago (Vultr)         :" "http://il-us-ping.vultr.com/vultr.com.100MB.bin"
	speed "USA, Kansas City (Joe's DC)  :" "https://lg.joesdatacenter.com/100MB.test"
	speed "USA, Denver (Mean Servers)   :" "http://den.meanservers.com/lg/100MB.tar.gz"
	speed "USA, Dallas (Vultr)          :" "http://tx-us-ping.vultr.com/vultr.com.100MB.bin"
	speed "USA, Atlanta (Vultr)         :" "http://ga-us-ping.vultr.com/vultr.com.100MB.bin"
	speed "USA, Miami (Vultr)           :" "https://fl-us-ping.vultr.com/vultr.com.100MB.bin"
	speed "USA, Phoenix (PhoenixNAP)    :" "http://phx.hostingsupport.io/downloadtest/100MB.bin"
	speed "USA, Los Angeles (Vultr)     :" "https://lax-ca-us-ping.vultr.com/vultr.com.100MB.bin"
	speed "USA, San Francisco (DO)      :" "http://speedtest-sfo2.digitalocean.com/100mb.test"
	speed "USA, Seattle (Vultr)         :" "http://wa-us-ping.vultr.com/vultr.com.100MB.bin"
	speed "Canada, Montreal (OVH)       :" "http://bhs.proof.ovh.net/files/100Mio.dat"
	speed "Canada, Toronto (Vultr)      :" "http://tor-ca-ping.vultr.com/vultr.com.100MB.bin"
	speed "Canada, Winnipeg (Bell)      :" "http://wnpcfspd02.srvr.bell.ca/speedtest/random4000x4000.jpg"
	speed "Canada, Edmonton (Switch)    :" "https://speedtest.switch.ca/speedtest/random4000x4000.jpg"
	speed "Mexico, Mexico City (C3NTRO) :" "http://sp1.c3ntro.com/speedtest/random4000x4000.jpg"
	speed "Puerto Rico, San Juan (Prepa):" "http://speedtest.prepanetworks.net/speedtest/random4000x4000.jpg"
	speed "Belize, Belize City (BTL)    :" "http://speedtest3.btl.net/speedtest/random4000x4000.jpg"
	speed "Panama, Panama City (Claro)  :" "http://speedtest1.claro.com.pa/speedtest/random4000x4000.jpg"
	echo ""
}

# 24 locations
europespeedtest () {
	echo "" | tee -a $log
	echostyle "## Europe Speedtest"
	echo "" | tee -a $log
	speed "United Kingdom, London (Vultr)  :" "http://lon-gb-ping.vultr.com/vultr.com.100MB.bin"
	speed "Netherlands, Amsterdam (Vultr)  :" "http://ams-nl-ping.vultr.com/vultr.com.100MB.bin"
	speed "Germany, Frankfurt (Linode)     :" "http://speedtest.frankfurt.linode.com/100MB-frankfurt.bin"
	speed "Germany, Nuremberg (NetCup)     :" "http://lookingglass.netcup.net/100MB.test"
	speed "France, Paris (Vultr)           :" "http://par-fr-ping.vultr.com/vultr.com.100MB.bin"
	speed "Spain, Madrid (M247)            :" "http://es.hosth.ink/100mb.bin"
	speed "Spain, Sevilla (Edis)           :" "https://es.edis.at/100MB.test"
	speed "Portugal, Lisbon (Evolute)      :" "http://speedtest1.evolute.pt/speedtest/random4000x4000.jpg"
	speed "Denmark, Copenhagen (Interxion) :" "http://dk.hosth.ink/100mb.bin"
	speed "Sweden, Stockholm (HostHatch)   :" "http://lg.sto.hosthatch.com/100MB.test"
	speed "Norway, Oslo (HostHatch)        :" "http://lg.osl.hosthatch.com/100MB.test"
	speed "Switzerland, Zurich (Interxion) :" "http://ch.hosth.ink/1000mb.bin"
	speed "Italy, Milan (Prometeus)        :" "http://lg-milano.prometeus.net/100MB.test"
	speed "Austria, Vienna (HostHatch)     :" "http://lg.vie.hosthatch.com/100MB.test"
	speed "Poland, Warsaw (Edis)           :" "https://pl.edis.at/100MB.test"
	speed "Russia, Moscow (FoxCloud)       :" "http://94.103.12.105/100.mb"
	speed "Russia, St.Petersburg (Hexcore) :" "http://92.255.99.30/100.mb"
	speed "Lithuania, Siauliai (UltraVPS)  :" "http://lg.sqq.lt.ultravps.eu/100MB.test"
	speed "Ukraine, Kyiv (KyivStar)        :" "http://speedtest.kyivstar.ua/speedtest/random4000x4000.jpg"
	speed "Moldova, Chisinau (ClouDedic)   :" "http://185.153.198.20/100.mb"
	speed "Romania, Bucharest (Orange)     :" "http://speedtestbuc.orangero.net/speedtest/random4000x4000.jpg"
	speed "Bulgaria, Sofia (AlphaVPS)      :" "http://lgbg.alphavps.bg/100MB.test"
	speed "Greece, Athens (GRNET)          :" "http://speed-test.gr-ix.gr/speedtest/random4000x4000.jpg"
	speed "Turkey, Istanbul (Radore)       :" "http://speedtest.radore.com/speedtest/random4000x4000.jpg"
	echo "" | tee -a $log
}

# 23 locations
ukrainespeedtest () {
	echo "" | tee -a $log
	echostyle "## Ukraine Speedtest"
	echo "" | tee -a $log
	speed "Ukraine, Kyiv (Ukrtelecom)       :" "http://95.47.137.63/100.mb"
	speed "Ukraine, Kyiv (KyivStar)         :" "http://speedtest.kyivstar.ua/speedtest/random4000x4000.jpg"
	speed "Ukraine, Kyiv (Volia)            :" "http://speedtest.volia.net/speedtest/random4000x4000.jpg"
	speed "Ukraine, Kyiv (Freenet)          :" "http://sp1.o3.ua/random4000x4000.jpg"
	speed "Ukraine, Lviv (UARnet)           :" "http://speedtest.uar.net/speedtest/random4000x4000.jpg"
	speed "Ukraine, Lviv (Komitex)          :" "http://speedtest.komitex.net/speedtest/random4000x4000.jpg"
	speed "Ukraine, Lviv (Astra)            :" "http://speedtest.astra.in.ua/speedtest/random4000x4000.jpg"
	speed "Ukraine, Ivano-Frankivsk (SIM)   :" "http://speedtest.sim.if.ua/speedtest/random4000x4000.jpg"
	speed "Ukraine, Uzhgorod (TransCom)     :" "http://speedtest.tcom.uz.ua/speedtest/speedtest/random4000x4000.jpg"
	speed "Ukraine, Ternopil (Columbus)     :" "http://speedtest.columbus.te.ua/speedtest/random4000x4000.jpg"
	speed "Ukraine, Rivne (UARnet)          :" "http://strivne.uar.net/speedtest/random4000x4000.jpg"
	speed "Ukraine, Chernivtsi (C.T.Net)    :" "http://speedtest.ctn.cv.ua/speedtest/random4000x4000.jpg"
	speed "Ukraine, Khmelnytskyi (GMHost)   :" "http://lg.gmhost.hosting/100MB.test"
	speed "Ukraine, Kropyvnytskyi (Imperial):" "http://speedtest.imperial.net.ua/speedtest/random4000x4000.jpg"
	speed "Ukraine, Cherkasy (McLaut)       :" "http://speedtest.mclaut.com/speedtest/random4000x4000.jpg"
	speed "Ukraine, Poltava (Triolan)       :" "http://poltava.speedtest.triolan.com.ua/speedtest/random4000x4000.jpg"
	speed "Ukraine, Chernihiv (UltraNet)    :" "http://speedtest.ultranet.com.ua/speedtest/random4000x4000.jpg"
	speed "Ukraine, Sumy (TKS)              :" "http://speedtest.tks.sumy.ua/speedtest/random4000x4000.jpg"
	speed "Ukraine, Kharkiv (Triolan)       :" "http://kharkiv.speedtest.triolan.com.ua/speedtest/random4000x4000.jpg"
	speed "Ukraine, Dnipro (D-lan)          :" "http://speedtest.d-lan.dp.ua/speedtest/random4000x4000.jpg"
	speed "Ukraine, Odesa (Black Sea)       :" "http://speedtest.blacksea.net.ua/speedtest/random4000x4000.jpg"
	speed "Ukraine, Kherson (SkyNET)        :" "http://sp.skynet.ua/speedtest/random4000x4000.jpg"
	speed "Ukraine, Mariupol (CityLine)     :" "http://speedtest.cl.dn.ua/speedtest/random4000x4000.jpg"
	echo "" | tee -a $log
}

# 16 locations
asiaspeedtest () {
	echo "" | tee -a $log
	echostyle "## Asia & Pacific Speedtest"
	echo "" | tee -a $log
	speed "India, Mumbai (Linode)              :" "http://speedtest.mumbai1.linode.com/100MB-mumbai.bin"
	speed "India, Bangalore (DigitalOcean)     :" "http://speedtest-blr1.digitalocean.com/100mb.test"
	speed "India, New Delhi (Weebo)            :" "http://sp1.weebo.in/speedtest/random4000x4000.jpg"
	speed "Singapore (Linode)                  :" "http://speedtest.singapore.linode.com/100MB-singapore.bin"
	speed "Hong Kong (LeaseWeb)                :" "http://mirror.hk.leaseweb.net/speedtest/100mb.bin"
	speed "Taiwan, Taipei (DignusData)         :" "http://185.253.156.22/100.mb"
	speed "South Korea, Seoul (G-Core Labs)    :" "http://92.38.135.28/100.mb"
	speed "Japan, Tokyo (Vultr)                :" "http://hnd-jp-ping.vultr.com/vultr.com.100MB.bin"
	speed "Thailand, Bangkok (TCC Technology)  :" "http://speedtest.tcc-technology.com/speedtest/random4000x4000.jpg"
	speed "Philippines, Davao (Skybroadband)   :" "http://speedtest-dvo.skybroadband.com.ph/speedtest/random4000x4000.jpg"
	speed "Indonesia, Makassar (Telekomunikasi):" "http://makasar.speedtest.telkom.net.id/speedtest/random4000x4000.jpg"
	speed "Australia, Sydney (Vultr)           :" "https://syd-au-ping.vultr.com/vultr.com.100MB.bin"
	speed "Australia, Perth (Superloop)        :" "http://sp02.au.superloop.com/speedtest/random4000x4000.jpg"
	speed "New Zealand, Auckland (Zappie Host) :" "https://lg-nz.zappiehost.com/100MB.test"
	speed "Hawaii, Honolulu (Hawaii .edu)      :" "http://mirror.ancl.hawaii.edu/linux/archlinux/iso/latest/archlinux-bootstrap-2019.09.01-x86_64.tar.gz"
	speed "Hawaii, Mauna Lani (Spectrum)       :" "http://kmlahi07-speedtest-01-a.hawaii.rr.com/speedtest/random4000x4000.jpg"
	echo "" | tee -a $log
}

# 9 locations
southamericaspeedtest () {
	echo "" | tee -a $log
	echostyle "## South America Speedtest"
	echo "" | tee -a $log
	speed "Brazil, Sao Paulo (SoftLayer)   :" "http://sao.speedtest.net/speedtest/random4000x4000.jpg"
	speed "Brazil, Fortaleza (Claro)       :" "http://spd1.claro.com.br/speedtest/random4000x4000.jpg"
	speed "Colombia, Bogota (UFINET)       :" "http://speedtest-bog.ufinet.com.co/speedtest/random4000x4000.jpg"
	speed "Ecuador, Quito (Iplanet)        :" "http://sp1.iplanet.ec/speedtest/random4000x4000.jpg"
	speed "Peru, Lima (Entel)              :" "http://speedtest.entel.net.pe/speedtest/random4000x4000.jpg"
	speed "Bolivia, La Paz (AXS)           :" "http://speedtest.axsbolivia.com/speedtest/random4000x4000.jpg"
	speed "Chile, Santiago (Netglobalis)   :" "http://speedtest.netglobalis.cl/speedtest/random4000x4000.jpg"
	speed "Paraguay, Asuncion (Claro)      :" "http://speedtest.claro.com.py/speedtest/random4000x4000.jpg"
	speed "Argentina, Buenos Aires (Claro) :" "http://speedtest.claro.com.ar/speedtest/random4000x4000.jpg"
	echo "" | tee -a $log
}

# 8 locations
morespeedtest () {
	echo "" | tee -a $log
	echostyle "## More locations Speedtest"
	echo "" | tee -a $log
	speed "Iceland, Reykjavik (Flokinet)            :" "https://is.as200651.net/100MB.bin"
	speed "South Africa, Johannesburg (Zappie Host) :" "https://lg-za.zappiehost.com/100MB.test"
	speed "Israel, Tel Aviv (Edis)                  :" "https://il.edis.at/100MB.test"
	speed "Saudi Arabia, Riyadh (Saudi Telecom)     :" "http://riy-maintest.saudi.net.sa/file3"
	speed "UAE, Dubai (Equinix)                     :" "http://ae.hosth.ink/100mb.bin"
	speed "Pakistan, Islamabad (Zong)               :" "http://speedtest-isb1.zong.com.pk/speedtest/random4000x4000.jpg"
	speed "Georgia, Tbilisi (Beeline)               :" "http://speedtest1.beeline.ge/speedtest/random4000x4000.jpg"
	speed "Egypt, Cairo (Orange)                    :" "http://speedtestob.orange.eg/speedtest/random4000x4000.jpg"
	echo "" | tee -a $log
}

freedisk() {
	# check free space
	freespace=$( df -m . | awk 'NR==2 {print $4}' )
	if [[ $freespace -ge 1024 ]]; then
		printf "%s" $((1024*2))
	elif [[ $freespace -ge 512 ]]; then
		printf "%s" $((512*2))
	elif [[ $freespace -ge 256 ]]; then
		printf "%s" $((256*2))
	elif [[ $freespace -ge 128 ]]; then
		printf "%s" $((128*2))
	else
		printf 1
	fi
}

averageio() {
	ioraw1=$( echo $1 | awk 'NR==1 {print $1}' )
		[ "$(echo $1 | awk 'NR==1 {print $2}')" == "GB/s" ] && ioraw1=$( awk 'BEGIN{print '$ioraw1' * 1024}' )
	ioraw2=$( echo $2 | awk 'NR==1 {print $1}' )
		[ "$(echo $2 | awk 'NR==1 {print $2}')" == "GB/s" ] && ioraw2=$( awk 'BEGIN{print '$ioraw2' * 1024}' )
	ioraw3=$( echo $3 | awk 'NR==1 {print $1}' )
		[ "$(echo $3 | awk 'NR==1 {print $2}')" == "GB/s" ] && ioraw3=$( awk 'BEGIN{print '$ioraw3' * 1024}' )
	ioall=$( awk 'BEGIN{print '$ioraw1' + '$ioraw2' + '$ioraw3'}' )
	ioavg=$( awk 'BEGIN{printf "%.1f", '$ioall' / 3}' )
	printf "%s" "$ioavg"
}

cpubench() {
	if hash $1 2>$NULL; then
		io=$( ( dd if=/dev/zero bs=512K count=$2 | $1 ) 2>&1 | grep 'copied' | awk -F, '{io=$NF} END { print io}' )
		if [[ $io != *"."* ]]; then
			printf "  %4i %s" "${io% *}" "${io##* }"
		else
			printf "%4i.%s" "${io%.*}" "${io#*.}"
		fi
	else
		printf " %s not found on system." "$1"
	fi
}

iotest () {
	echo "" | tee -a $log
	echostyle "## IO Test"
	echo "" | tee -a $log

	# start testing
	writemb=$(freedisk)
	if [[ $writemb -gt 512 ]]; then
		writemb_size="$(( writemb / 2 / 2 ))MB"
		writemb_cpu="$(( writemb / 2 ))"
	else
		writemb_size="$writemb"MB
		writemb_cpu=$writemb
	fi

	# CPU Speed test
	printf " CPU Speed:\n" | tee -a $log
	printf "    bzip2 %s -" "$writemb_size" | tee -a $log
	printf "%s\n" "$( cpubench bzip2 $writemb_cpu )" | tee -a $log 
	printf "   sha256 %s -" "$writemb_size" | tee -a $log
	printf "%s\n" "$( cpubench sha256sum $writemb_cpu )" | tee -a $log
	printf "   md5sum %s -" "$writemb_size" | tee -a $log
	printf "%s\n\n" "$( cpubench md5sum $writemb_cpu )" | tee -a $log

	# Disk test
	echo " Disk Speed ($writemb_size):" | tee -a $log
	if [[ $writemb != "1" ]]; then
		io=$( ( dd bs=512K count=$writemb if=/dev/zero of=test; rm -f test ) 2>&1 | awk -F, '{io=$NF} END { print io}' )
		echo "   I/O Speed  -$io" | tee -a $log

		io=$( ( dd bs=512K count=$writemb if=/dev/zero of=test oflag=dsync; rm -f test ) 2>&1 | awk -F, '{io=$NF} END { print io}' )
		echo "   I/O Direct -$io" | tee -a $log
	else
		echo "   Not enough space to test." | tee -a $log
	fi
	echo "" | tee -a $log
	
	# Disk test
	echo " dd: sequential write speed:" | tee -a $log
	if [[ $writemb != "1" ]]; then
		io=$( ( dd if=/dev/zero of=test bs=64k count=16k conv=fdatasync; rm -f test ) 2>&1 | awk -F, '{io=$NF} END { print io}' )
		echo "   1st run: $io" | tee -a $log
		io=$( ( dd if=/dev/zero of=test bs=64k count=16k conv=fdatasync; rm -f test ) 2>&1 | awk -F, '{io=$NF} END { print io}' )
		echo "   2nd run: $io" | tee -a $log
		io=$( ( dd if=/dev/zero of=test bs=64k count=16k conv=fdatasync; rm -f test ) 2>&1 | awk -F, '{io=$NF} END { print io}' )
		echo "   3rd run: $io" | tee -a $log
	else
		echo "   Not enough space to test." | tee -a $log
	fi
	echo "" | tee -a $log

	# RAM Speed test
	# set ram allocation for mount
	tram_mb="$( free -m | grep Mem | awk 'NR=1 {print $2}' )"
	if [[ tram_mb -gt 1900 ]]; then
		sbram=1024M
		sbcount=2048
	else
		sbram=$(( tram_mb / 2 ))M
		sbcount=$tram_mb
	fi
	[[ -d $benchram ]] || mkdir $benchram
	mount -t tmpfs -o size=$sbram tmpfs $benchram/
	printf " RAM Speed (%sB):\n" "$sbram" | tee -a $log
	iow1=$( ( dd if=/dev/zero of=$benchram/zero bs=512K count=$sbcount ) 2>&1 | awk -F, '{io=$NF} END { print io}' )
	ior1=$( ( dd if=$benchram/zero of=$NULL bs=512K count=$sbcount; rm -f test ) 2>&1 | awk -F, '{io=$NF} END { print io}' )
	iow2=$( ( dd if=/dev/zero of=$benchram/zero bs=512K count=$sbcount ) 2>&1 | awk -F, '{io=$NF} END { print io}' )
	ior2=$( ( dd if=$benchram/zero of=$NULL bs=512K count=$sbcount; rm -f test ) 2>&1 | awk -F, '{io=$NF} END { print io}' )
	iow3=$( ( dd if=/dev/zero of=$benchram/zero bs=512K count=$sbcount ) 2>&1 | awk -F, '{io=$NF} END { print io}' )
	ior3=$( ( dd if=$benchram/zero of=$NULL bs=512K count=$sbcount; rm -f test ) 2>&1 | awk -F, '{io=$NF} END { print io}' )
	echo "   Avg. write - $(averageio "$iow1" "$iow2" "$iow3") MB/s" | tee -a $log
	echo "   Avg. read  - $(averageio "$ior1" "$ior2" "$ior3") MB/s" | tee -a $log
	rm $benchram/zero
	umount $benchram
	rm -rf $benchram
	echo "" | tee -a $log
}

speedtestresults () {
	#Testing Speedtest
	if hash python 2>$NULL; then
		curl -Lso speedtest-cli https://raw.githubusercontent.com/sivel/speedtest-cli/master/speedtest.py
		python speedtest-cli --share | tee -a $log
		rm -f speedtest-cli
		echo ""
	else
		echo " Python is not installed."
		echo " First install python, then re-run the script."
		echo ""
	fi
}

finishedon() {
	end_seconds=$(date +%s)
	echo " Benchmark finished in $((end_seconds-start_seconds)) seconds" | tee -a $log
	echo "   results saved on $log"
	echo "" | tee -a $log
	rm -f bench.sh
}

sharetest() {
	case $1 in
	'ubuntu')
		share_link=$( curl -v --data-urlencode "content@$log" -d "poster=benchmonster.log" -d "syntax=text" "https://paste.ubuntu.com" 2>&1 | \
			grep "Location" | awk '{print "https://paste.ubuntu.com"$3}' );;
	'haste' )
		share_link=$( curl -X POST -s -d "$(cat $log)" https://hastebin.com/documents | awk -F '"' '{print "https://hastebin.com/"$4}' );;
	'clbin' )
		share_link=$( curl -sF 'clbin=<-' https://clbin.com < $log );;
	esac

	# print result info
	echo " Share result:"
	echo " $share_link"
	echo ""

}

case $CMD in
	'-info'|'-information'|'--info'|'--information' )
		systeminfo;;
	'-io'|'-drivespeed'|'--io'|'--drivespeed' )
		iotest;;
	'-northamerica'|'-na'|'--northamerica'|'--na' )
		benchinit; systeminfo; iotest; cdnspeedtest; northamericaspeedtest; finishedon;;
	'-naspeed'|'--naspeed' )
		benchinit; cdnspeedtest; northamericaspeedtest; finishedon;;
	'-europe'|'-eu'|'--europe'|'--eu' )
		benchinit; systeminfo; iotest; cdnspeedtest; europespeedtest; finishedon;;
	'-euspeed'|'--euspeed' )
		benchinit; cdnspeedtest; europespeedtest; finishedon;;
	'-ukraine'|'-ua'|'--ukraine'|'--ua' )
		benchinit; systeminfo; iotest; cdnspeedtest; ukrainespeedtest; finishedon;;
	'-uaspeed'|'--uaspeed' )
		benchinit; cdnspeedtest; ukrainespeedtest; finishedon;;
	'-asia'|'--asia' )
		benchinit; systeminfo; iotest; cdnspeedtest; asiaspeedtest; finishedon;;
	'-asiaspeed'|'--asiaspeed' )
		benchinit; cdnspeedtest; asiaspeedtest; finishedon;;
	'-southamerica'|'-sa'|'--southamerica'|'--sa' )
		benchinit; systeminfo; iotest; cdnspeedtest; southamericaspeedtest; finishedon;;
	'-saspeed'|'--saspeed' )
		benchinit; cdnspeedtest; southamericaspeedtest; finishedon;;
	'-more'|'--more' )
		benchinit; morespeedtest; finishedon;;
	'-cdn'|'--cdn' )
		benchinit; cdnspeedtest; finishedon;;
	'-b'|'--b' )
		benchinit; systeminfo; cdnspeedtest; iotest; finishedon;;
	'-a'|'-all'|'-bench'|'--a'|'--all'|'--bench' )
		benchinit; systeminfo; iotest; cdnspeedtest; northamericaspeedtest;
		europespeedtest; asiaspeedtest; southamericaspeedtest; morespeedtest; finishedon;;
	'-speed'|'-speedtest'|'-speedcheck'|'--speed'|'--speedtest'|'--speedcheck' )
		benchinit; speedtestresults; finishedon;;
	'-help'|'--help'|'help' )
		prms;;
	'-about'|'--about'|'about' )
		about;;
	*)
		howto;;
esac

case $PRM1 in
	'-share'|'--share'|'share' )
		if [[ $PRM2 == "" ]]; then
			sharetest clbin
		else
			sharetest $PRM2
		fi
		;;
esac

# ring a bell
printf '\007'
