pragma Singleton

pragma ComponentBehavior

import QtQuick
import Quickshell
import Quickshell.Io
import qs.Services

Singleton {
  id: root
  property int refCount: 0
  property int updateInterval: refCount > 0 ? 3000 : 30000
  property int maxProcesses: 100
  property bool isUpdating: false
  property bool staticDataInitialized: false

  property var processes: []
  property string sortBy: "cpu"
  property bool sortDescending: true
  property var lastProcTicks: ({})
  property real lastTotalJiffies: -1

  property real cpuUsage: 0
  property real totalCpuUsage: 0
  property int cpuCores: 1
  property int cpuCount: 1
  property string cpuModel: ""
  property real cpuFrequency: 0
  property real cpuTemperature: -1
  property var perCoreCpuUsage: []

  property var lastCpuStats: null
  property var lastPerCoreStats: null

  property real memoryUsage: 0
  property real totalMemoryMB: 0
  property real usedMemoryMB: 0
  property real freeMemoryMB: 0
  property real availableMemoryMB: 0
  property int totalMemoryKB: 0
  property int usedMemoryKB: 0
  property int totalSwapKB: 0
  property int usedSwapKB: 0

  property real networkRxRate: 0
  property real networkTxRate: 0
  property var lastNetworkStats: null

  property real diskReadRate: 0
  property real diskWriteRate: 0
  property var lastDiskStats: null
  property var diskMounts: []

  property int historySize: 60
  property var cpuHistory: []
  property var memoryHistory: []
  property var networkHistory: ({
                                  "rx": [],
                                  "tx": []
                                })
  property var diskHistory: ({
                               "read": [],
                               "write": []
                             })

  property string kernelVersion: ""
  property string distribution: ""
  property string hostname: ""
  property string architecture: ""
  property string loadAverage: ""
  property int processCount: 0
  property int threadCount: 0
  property string bootTime: ""
  property string motherboard: ""
  property string biosVersion: ""
  property var availableGpus: []

  function addRef() {
    refCount++
    if (refCount === 1) {
      if (!staticDataInitialized) {
        initializeStaticData()
      }
      updateAllStats()
    }
  }

  function removeRef() {
    refCount = Math.max(0, refCount - 1)
  }

  function initializeStaticData() {
    if (!staticDataInitialized) {
      staticDataInitialized = true
      staticDataProcess.running = true
    }
  }

  function updateAllStats() {
    if (refCount > 0) {
      isUpdating = true
      dynamicStatsProcess.running = true
    }
  }

  function setSortBy(newSortBy) {
    if (newSortBy !== sortBy) {
      sortBy = newSortBy
      sortProcessesInPlace()
    }
  }

  function toggleSortOrder() {
    sortDescending = !sortDescending
    sortProcessesInPlace()
  }

  function sortProcessesInPlace() {
    if (processes.length === 0)
      return
    const sortedProcesses = [...processes]

    sortedProcesses.sort((a, b) => {
                           let aVal, bVal

                           switch (sortBy) {
                             case "cpu":
                             aVal = parseFloat(a.cpu) || 0
                             bVal = parseFloat(b.cpu) || 0
                             break
                             case "memory":
                             aVal = parseFloat(a.memoryPercent) || 0
                             bVal = parseFloat(b.memoryPercent) || 0
                             break
                             case "name":
                             aVal = a.command || ""
                             bVal = b.command || ""
                             break
                             case "pid":
                             aVal = parseInt(a.pid) || 0
                             bVal = parseInt(b.pid) || 0
                             break
                             default:
                             aVal = parseFloat(a.cpu) || 0
                             bVal = parseFloat(b.cpu) || 0
                           }

                           if (typeof aVal === "string") {
                             return sortDescending ? bVal.localeCompare(
                                                       aVal) : aVal.localeCompare(
                                                       bVal)
                           } else {
                             return sortDescending ? bVal - aVal : aVal - bVal
                           }
                         })

    processes = sortedProcesses
  }

  function killProcess(pid) {
    if (pid > 0) {
      Quickshell.execDetached("kill", [pid.toString()])
    }
  }

  function addToHistory(array, value) {
    array.push(value)
    if (array.length > historySize)
      array.shift()
  }

  function calculateCpuUsage(currentStats, lastStats) {
    if (!lastStats || !currentStats || currentStats.length < 4) {
      return 0
    }

    const currentTotal = currentStats.reduce((sum, val) => sum + val, 0)
    const lastTotal = lastStats.reduce((sum, val) => sum + val, 0)

    const totalDiff = currentTotal - lastTotal
    if (totalDiff <= 0)
      return 0

    const currentIdle = currentStats[3]
    const lastIdle = lastStats[3]
    const idleDiff = currentIdle - lastIdle

    const usedDiff = totalDiff - idleDiff
    return Math.max(0, Math.min(100, (usedDiff / totalDiff) * 100))
  }

  function parseStaticData(data) {
    if (data.cpu) {
      cpuCores = data.cpu.count || 1
      cpuCount = data.cpu.count || 1
      cpuModel = data.cpu.model || ""
    }

    if (data.system) {
      kernelVersion = data.system.kernel || ""
      distribution = data.system.distro || ""
      hostname = data.system.hostname || ""
      architecture = data.system.arch || ""
      motherboard = data.system.motherboard || ""
      biosVersion = data.system.bios || ""
    }

    if (data.gpus) {
      const gpuList = []
      for (const gpu of data.gpus) {
        // Parse the display name from rawLine
        let displayName = ""
        let fullName = ""
        
        if (gpu.rawLine) {
          // Remove BDF and class prefix
          let s = gpu.rawLine.replace(/^[^:]+: /, "")
          // Remove PCI ID [vvvv:dddd] and everything after
          s = s.replace(/\[[0-9a-f]{4}:[0-9a-f]{4}\].*$/i, "")
          
          // Try to extract text after last ']'
          const afterBracket = s.match(/\]\s*([^\[]+)$/)
          if (afterBracket && afterBracket[1].trim()) {
            displayName = afterBracket[1].trim()
          } else {
            // Try to get last bracketed text
            const lastBracket = s.match(/\[([^\]]+)\]([^\[]*$)/)
            if (lastBracket) {
              displayName = lastBracket[1]
            } else {
              displayName = s
            }
          }
          
          // Remove vendor prefixes
          displayName = displayName
            .replace(/^NVIDIA Corporation\s+/i, "")
            .replace(/^NVIDIA\s+/i, "")
            .replace(/^GeForce\s+/i, "")
            .replace(/^Advanced Micro Devices, Inc\.\s+/i, "")
            .replace(/^AMD\/ATI\s+/i, "")
            .replace(/^AMD\s+/i, "")
            .replace(/^ATI\s+/i, "")
            .replace(/^Intel Corporation\s+/i, "")
            .replace(/^Intel\s+/i, "")
            .trim()
        } else if (gpu.rawLine && gpu.rawLine.startsWith("NVIDIA")) {
          // nvidia-smi fallback case
          displayName = gpu.rawLine.replace(/^NVIDIA\s+/, "")
        } else {
          displayName = "Unknown"
        }
        
        // Build full name with vendor prefix
        switch(gpu.vendor) {
          case "NVIDIA": fullName = "NVIDIA " + displayName; break
          case "AMD": fullName = "AMD " + displayName; break
          case "Intel": fullName = "Intel " + displayName; break
          default: fullName = displayName
        }
        
        gpuList.push({
          "driver": gpu.driver,
          "vendor": gpu.vendor,
          "displayName": displayName,
          "fullName": fullName,
          "temperature": 0,
          "hwmon": "unknown"
        })
      }
      availableGpus = gpuList
    }
  }

  function parseDynamicStats(data) {
    updateGpuTemperatures(data.gputemps || [])
    parseUnifiedStats(JSON.stringify(data))
  }

  function updateGpuTemperatures(tempData) {
    if (availableGpus.length === 0 || tempData.length === 0) return
    
    const updatedGpus = []
    for (let i = 0; i < availableGpus.length; i++) {
      const gpu = availableGpus[i]
      const tempInfo = tempData.find(t => t.driver === gpu.driver)
      if (tempInfo) {
        updatedGpus.push({
          "driver": gpu.driver,
          "vendor": gpu.vendor,
          "displayName": gpu.displayName,
          "fullName": gpu.fullName,
          "temperature": tempInfo.temperature || 0,
          "hwmon": tempInfo.hwmon || "unknown"
        })
      } else {
        updatedGpus.push({
          "driver": gpu.driver,
          "vendor": gpu.vendor,
          "displayName": gpu.displayName,
          "fullName": gpu.fullName,
          "temperature": gpu.temperature || 0,
          "hwmon": gpu.hwmon || "unknown"
        })
      }
    }
    availableGpus = updatedGpus
  }

  function parseUnifiedStats(text) {
    function num(x) {
      return (typeof x === "number" && !isNaN(x)) ? x : 0
    }

    let data
    try {
      data = JSON.parse(text)
    } catch (error) {
      isUpdating = false
      return
    }

    if (data.memory) {
      const m = data.memory
      totalMemoryKB = num(m.total)
      const free = num(m.free)
      const buf = num(m.buffers)
      const cached = num(m.cached)
      const shared = num(m.shared)
      usedMemoryKB = totalMemoryKB - free - buf - cached
      totalSwapKB = num(m.swaptotal)
      usedSwapKB = num(m.swaptotal) - num(m.swapfree)
      totalMemoryMB = totalMemoryKB / 1024
      usedMemoryMB = usedMemoryKB / 1024
      freeMemoryMB = (totalMemoryKB - usedMemoryKB) / 1024
      availableMemoryMB = num(
            m.available) ? num(
                             m.available) / 1024 : (free + buf + cached) / 1024
      memoryUsage = totalMemoryKB > 0 ? (usedMemoryKB / totalMemoryKB) * 100 : 0
    }

    if (data.cpu) {
      cpuFrequency = data.cpu.frequency || 0
      cpuTemperature = data.cpu.temperature || 0

      if (data.cpu.total && data.cpu.total.length >= 8) {
        const currentStats = data.cpu.total
        const usage = calculateCpuUsage(currentStats, lastCpuStats)
        cpuUsage = usage
        totalCpuUsage = usage
        lastCpuStats = [...currentStats]
      }

      if (data.cpu.cores) {
        const coreUsages = []
        for (var i = 0; i < data.cpu.cores.length; i++) {
          const currentCoreStats = data.cpu.cores[i]
          if (currentCoreStats && currentCoreStats.length >= 8) {
            let lastCoreStats = null
            if (lastPerCoreStats && lastPerCoreStats[i]) {
              lastCoreStats = lastPerCoreStats[i]
            }

            const usage = calculateCpuUsage(currentCoreStats, lastCoreStats)
            coreUsages.push(usage)
          }
        }

        if (JSON.stringify(perCoreCpuUsage) !== JSON.stringify(coreUsages)) {
          perCoreCpuUsage = coreUsages
        }

        lastPerCoreStats = data.cpu.cores.map(core => [...core])
      }
    }

    if (data.network) {
      let totalRx = 0
      let totalTx = 0
      for (const iface of data.network) {
        totalRx += iface.rx
        totalTx += iface.tx
      }
      if (lastNetworkStats) {
        const timeDiff = updateInterval / 1000
        const rxDiff = totalRx - lastNetworkStats.rx
        const txDiff = totalTx - lastNetworkStats.tx
        networkRxRate = Math.max(0, rxDiff / timeDiff)
        networkTxRate = Math.max(0, txDiff / timeDiff)
        addToHistory(networkHistory.rx, networkRxRate / 1024)
        addToHistory(networkHistory.tx, networkTxRate / 1024)
      }
      lastNetworkStats = {
        "rx": totalRx,
        "tx": totalTx
      }
    }

    if (data.disk) {
      let totalRead = 0
      let totalWrite = 0
      for (const disk of data.disk) {
        totalRead += disk.read * 512
        totalWrite += disk.write * 512
      }
      if (lastDiskStats) {
        const timeDiff = updateInterval / 1000
        const readDiff = totalRead - lastDiskStats.read
        const writeDiff = totalWrite - lastDiskStats.write
        diskReadRate = Math.max(0, readDiff / timeDiff)
        diskWriteRate = Math.max(0, writeDiff / timeDiff)
        addToHistory(diskHistory.read, diskReadRate / (1024 * 1024))
        addToHistory(diskHistory.write, diskWriteRate / (1024 * 1024))
      }
      lastDiskStats = {
        "read": totalRead,
        "write": totalWrite
      }
    }

    let totalDiff = 0
    if (data.cpu && data.cpu.total && data.cpu.total.length >= 4) {
      const currentTotal = data.cpu.total.reduce((s, v) => s + v, 0)
      if (lastTotalJiffies > 0)
        totalDiff = currentTotal - lastTotalJiffies
      lastTotalJiffies = currentTotal
    }

    if (data.processes) {
      const newProcesses = []
      for (const proc of data.processes) {
        const pid = proc.pid
        const pticks = Number(proc.pticks) || 0
        const prev = lastProcTicks[pid] ?? null
        let cpuShare = 0

        if (prev !== null && totalDiff > 0) {
          // Per share all CPUs (matches gnome system monitor)
          //cpuShare = 100 * Math.max(0, pticks - prev) / totalDiff

          // per-share per-core
          cpuShare = 100 * cpuCores * Math.max(0, pticks - prev) / totalDiff
        }

        lastProcTicks[pid] = pticks // update cache

        newProcesses.push({
                            "pid": pid,
                            "ppid": proc.ppid,
                            "cpu": cpuShare,
                            "memoryPercent": proc.pssPercent
                                             ?? proc.memoryPercent,
                            "memoryKB": proc.pssKB ?? proc.memoryKB,
                            "command": proc.command,
                            "fullCommand": proc.fullCommand,
                            "displayName": (proc.command && proc.command.length
                                            > 15) ? proc.command.substring(
                                                      0,
                                                      15) + "..." : proc.command
                          })
      }
      processes = newProcesses
      sortProcessesInPlace()
    }

    if (data.system) {
      loadAverage = data.system.loadavg || ""
      processCount = data.system.processes || 0
      threadCount = data.system.threads || 0
      bootTime = data.system.boottime || ""
    }

    if (data.diskmounts) {
      diskMounts = data.diskmounts
    }


    addToHistory(cpuHistory, cpuUsage)
    addToHistory(memoryHistory, memoryUsage)

    isUpdating = false
  }

  function getProcessIcon(command) {
    const cmd = command.toLowerCase()
    if (cmd.includes("firefox") || cmd.includes("chrome") || cmd.includes(
          "browser"))
      return "web"
    if (cmd.includes("code") || cmd.includes("editor") || cmd.includes("vim"))
      return "code"
    if (cmd.includes("terminal") || cmd.includes("bash") || cmd.includes("zsh"))
      return "terminal"
    if (cmd.includes("music") || cmd.includes("audio") || cmd.includes(
          "spotify"))
      return "music_note"
    if (cmd.includes("video") || cmd.includes("vlc") || cmd.includes("mpv"))
      return "play_circle"
    if (cmd.includes("systemd") || cmd.includes("kernel") || cmd.includes(
          "kthread"))
      return "settings"
    return "memory"
  }

  function formatCpuUsage(cpu) {
    return (cpu || 0).toFixed(1) + "%"
  }

  function formatMemoryUsage(memoryKB) {
    const mem = memoryKB || 0
    if (mem < 1024)
      return mem.toFixed(0) + " KB"
    else if (mem < 1024 * 1024)
      return (mem / 1024).toFixed(1) + " MB"
    else
      return (mem / (1024 * 1024)).toFixed(1) + " GB"
  }

  function formatSystemMemory(memoryKB) {
    const mem = memoryKB || 0
    if (mem < 1024 * 1024)
      return (mem / 1024).toFixed(0) + " MB"
    else
      return (mem / (1024 * 1024)).toFixed(1) + " GB"
  }

  Timer {
    id: updateTimer
    interval: root.updateInterval
    running: root.refCount > 0
    repeat: true
    triggeredOnStart: true
    onTriggered: root.updateAllStats()
  }

readonly property string staticDataScript: `exec 2>/dev/null
  set -o pipefail
  json_escape() { sed -e 's/\\\\/\\\\\\\\/g' -e 's/"/\\\\"/g' -e ':a;N;$!ba;s/\\n/\\\\n/g'; }

  printf "{"

  cpu_count=$(nproc)
  cpu_model=$(grep -m1 'model name' /proc/cpuinfo | cut -d: -f2- | sed 's/^ *//' | json_escape || echo 'Unknown')
  
  printf '"cpu":{"count":%d,"model":"%s"},' "$cpu_count" "$cpu_model"

  dmip="/sys/class/dmi/id"
  [ -d "$dmip" ] || dmip="/sys/devices/virtual/dmi/id"
  mb_vendor=$([ -r "$dmip/board_vendor" ] && cat "$dmip/board_vendor" | json_escape || echo "Unknown")
  mb_name=$([ -r "$dmip/board_name" ] && cat "$dmip/board_name" | json_escape || echo "")
  bios_ver=$([ -r "$dmip/bios_version" ] && cat "$dmip/bios_version" | json_escape || echo "Unknown")
  bios_date=$([ -r "$dmip/bios_date" ] && cat "$dmip/bios_date" | json_escape || echo "")

  kern_ver=$(uname -r | json_escape)
  distro=$(grep PRETTY_NAME /etc/os-release 2>/dev/null | cut -d= -f2- | tr -d '"' | json_escape || echo 'Unknown')
  host_name=$(hostname | json_escape)
  arch_name=$(uname -m)

  printf '"system":{"kernel":"%s","distro":"%s","hostname":"%s","arch":"%s","motherboard":"%s %s","bios":"%s %s"},' \\
  "$kern_ver" "$distro" "$host_name" "$arch_name" "$mb_vendor" "$mb_name" "$bios_ver" "$bios_date"

  printf '"gpus":['
  gfirst=1
  tmp_gpu=$(mktemp)

  # Map driver -> vendor, else infer from lspci line
  infer_vendor() {
    case "$1" in
      nvidia|nouveau) echo NVIDIA ;;
      amdgpu|radeon) echo AMD ;;
      i915|xe) echo Intel ;;
      *) case "$2" in
           *NVIDIA*|*Nvidia*|*nvidia*) echo NVIDIA ;;
           *AMD*|*ATI*|*amd*|*ati*)    echo AMD ;;
           *Intel*|*intel*)            echo Intel ;;
           *)                          echo Unknown ;;
         esac ;;
    esac
  }

  # Priority for sorting (nvidia first, then dGPU AMD, then iGPU AMD/Intel)
  prio_of() {
    local drv="$1" bdf="$2"
    case "$drv" in
      nvidia) echo 3 ;;
      amdgpu|radeon)
        # crude: device number from BDF 0000:BB:DD.F  -> DD
        local dd="\${bdf##*:}"; dd="\${dd%%.*}"
        [ "$dd" = "00" ] && echo 1 || echo 2
        ;;
      i915|xe) echo 0 ;;
      *) echo 0 ;;
    esac
  }

  # Enumerate all VGA/3D/2D/Display devices (domain-aware)
  LC_ALL=C lspci -nnD 2>/dev/null | grep -iE ' VGA| 3D| 2D| Display' | while IFS= read -r line; do
    bdf="\${line%% *}"                                       # 0000:BB:DD.F
    short_bdf="\${bdf#0000:}"

    # kernel driver in use
    drv=""; vendor="Unknown"
    if [ -e "/sys/bus/pci/devices/\$bdf/driver" ]; then
      drv="$(basename "$(readlink -f "/sys/bus/pci/devices/\$bdf/driver")")"
    fi

    vendor="$(infer_vendor "\$drv" "\$line")"

    # Just pass the raw line, we'll parse it in JavaScript
    raw_line="$(printf '%s' "\$line" | json_escape)"

    # priority for sorting
    prio="$(prio_of "\$drv" "\$bdf")"

    printf '%s|%s|%s|%s\\n' "\$prio" "\$drv" "\$vendor" "\$raw_line" >> "\$tmp_gpu"
  done

  # Output JSON
  if [ -s "\$tmp_gpu" ]; then
    while IFS='|' read -r pr drv vendor raw_line; do
      [ \$gfirst -eq 1 ] || printf ","
      printf '{"driver":"%s","vendor":"%s","rawLine":"%s"}' \\
        "\$drv" "\$vendor" "\$raw_line"
      gfirst=0
    done < <(sort -t'|' -k1,1nr -k2,2 "\$tmp_gpu")
  fi

  rm -f "\$tmp_gpu"
  printf ']'

  printf "}\\n"`

  readonly property string dynamicDataScript: `
  sort_key=\${1:-cpu}
  max_procs=\${2:-20}

  json_escape() { sed -e 's/\\\\/\\\\\\\\/g' -e 's/"/\\\\"/g' -e ':a;N;$!ba;s/\\n/\\\\n/g'; }

  printf "{"

  mem_line="$(awk '/^MemTotal:/{t=$2}
  /^MemFree:/{f=$2}
  /^MemAvailable:/{a=$2}
  /^Buffers:/{b=$2}
  /^Cached:/{c=$2}
  /^Shmem:/{s=$2}
  /^SwapTotal:/{st=$2}
  /^SwapFree:/{sf=$2}
  END{printf "%d %d %d %d %d %d %d %d",t,f,a,b,c,s,st,sf}' /proc/meminfo)"
  read -r MT MF MA BU CA SH ST SF <<< "$mem_line"
  printf '"memory":{"total":%d,"free":%d,"available":%d,"buffers":%d,"cached":%d,"shared":%d,"swaptotal":%d,"swapfree":%d},' \\
  "$MT" "$MF" "$MA" "$BU" "$CA" "$SH" "$ST" "$SF"

  # Get pss per pid
  get_pss_kb() {
  # Read PSS with zero external processes.
  # 1) Prefer smaps_rollup (fast, single file)
  # 2) Fallback to summing PSS in smaps
  # Return 0 if unavailable.
  local pid="$1" f total v k _
  f="/proc/$pid/smaps_rollup"
  if [ -r "$f" ]; then
  # smaps_rollup has one Pss: line — read it directly
  while read -r k v _; do
  if [ "$k" = "Pss:" ]; then
  printf '%s\n' "\${v:-0}"
  return
  fi
  done < "$f"
  printf '0\n'
  return
  fi
  f="/proc/$pid/smaps"
  if [ -r "$f" ]; then
  total=0
  while read -r k v _; do
  [ "$k" = "Pss:" ] && total=$(( total + (v:-0) ))
  done < "$f"
  printf '%s\n' "$total"
  return
  fi
  printf '0\n'
  }

  cpu_count=$(nproc)
  cpu_model=$(grep -m1 'model name' /proc/cpuinfo | cut -d: -f2- | sed 's/^ *//' | json_escape || echo 'Unknown')
  cpu_freq=$(awk -F: '/cpu MHz/{gsub(/ /,"",$2);print $2;exit}' /proc/cpuinfo || echo 0)
  cpu_temp=0
  for hwmon_dir in /sys/class/hwmon/hwmon*/; do
  [ -d "$hwmon_dir" ] || continue
  name_file="\${hwmon_dir}name"
  [ -r "$name_file" ] || continue

  # Check if this hwmon is for CPU temperature
  if grep -qE 'coretemp|k10temp|k8temp|cpu_thermal|soc_thermal' "$name_file" 2>/dev/null; then
  # Look for temperature files without using wildcards in quotes
  for temp_file in "\${hwmon_dir}"temp*_input; do
  if [ -r "$temp_file" ]; then
  cpu_temp=$(awk '{printf "%.1f", $1/1000}' "$temp_file" 2>/dev/null || echo 0)
  break 2  # Break both loops
  fi
  done
  fi
  done

  printf '"cpu":{"count":%d,"model":"%s","frequency":%s,"temperature":%s,' \\
  "$cpu_count" "$cpu_model" "$cpu_freq" "$cpu_temp"

  printf '"total":'
  awk 'NR==1 {
  printf "[";
  for(i=2; i<=NF; i++) {
  if(i>2) printf ",";
  printf "%d", $i;
  }
  printf "]";
  exit
  }' /proc/stat

  printf ',"cores":['
  cpu_cores=$(nproc)
  awk -v n="$cpu_cores" 'BEGIN{c=0}
  /^cpu[0-9]+/ {
  if(c>0) printf ",";
  printf "[%d,%d,%d,%d,%d,%d,%d,%d]", $2,$3,$4,$5,$6,$7,$8,$9;
  c++;
  if(c==n) exit
  }' /proc/stat
  printf ']},'

  printf '"network":['
  tmp_net=$(mktemp)
  grep -E '(wlan|eth|enp|wlp|ens|eno)' /proc/net/dev > "$tmp_net" || true
  nfirst=1
  while IFS= read -r line; do
  [ -z "$line" ] && continue
  iface=$(echo "$line" | awk '{print $1}' | sed 's/://')
  rx_bytes=$(echo "$line" | awk '{print $2}')
  tx_bytes=$(echo "$line" | awk '{print $10}')
  [ $nfirst -eq 1 ] || printf ","
  printf '{"name":"%s","rx":%d,"tx":%d}' "$iface" "$rx_bytes" "$tx_bytes"
  nfirst=0
  done < "$tmp_net"
  rm -f "$tmp_net"
  printf '],'

  printf '"disk":['
  tmp_disk=$(mktemp)
  grep -E ' (sd[a-z]+|nvme[0-9]+n[0-9]+|vd[a-z]+|dm-[0-9]+|mmcblk[0-9]+) ' /proc/diskstats > "$tmp_disk" || true
  dfirst=1
  while IFS= read -r line; do
  [ -z "$line" ] && continue
  name=$(echo "$line" | awk '{print $3}')
  read_sectors=$(echo "$line" | awk '{print $6}')
  write_sectors=$(echo "$line" | awk '{print $10}')
  [ $dfirst -eq 1 ] || printf ","
  printf '{"name":"%s","read":%d,"write":%d}' "$name" "$read_sectors" "$write_sectors"
  dfirst=0
  done < "$tmp_disk"
  rm -f "$tmp_disk"
  printf '],'

  printf '"processes":['
  case "$sort_key" in
  cpu)    SORT_OPT="--sort=-pcpu" ;;
  memory) SORT_OPT="--sort=-pmem" ;;
  name)   SORT_OPT="--sort=+comm" ;;
  pid)    SORT_OPT="--sort=+pid" ;;
  *)      SORT_OPT="--sort=-pcpu" ;;
  esac

  tmp_ps=$(mktemp)
  ps -eo pid,ppid,pcpu,pmem,rss,comm,cmd --no-headers $SORT_OPT | head -n "$max_procs" > "$tmp_ps" || true

  pfirst=1
  while IFS=' ' read -r pid ppid cpu pmem_rss rss_kib comm rest; do
  [ -z "$pid" ] && continue

  # Per-process CPU ticks (utime+stime)
  pticks=$(awk '{print $14+$15}' "/proc/$pid/stat" 2>/dev/null || echo 0)

  if [ "\${rss_kib:-0}" -eq 0 ]; then pss_kib=0; else pss_kib=$(get_pss_kb "$pid"); fi
  case "$pss_kib" in (''|*[!0-9]*) pss_kib=0 ;; esac
  pss_pct=$(LC_ALL=C awk -v p="$pss_kib" -v t="$MT" 'BEGIN{if(t>0) printf "%.2f", (100*p)/t; else printf "0.00"}')

  cmd=$(printf "%s %s" "$comm" "\${rest:-}" | json_escape)
  comm_esc=$(printf "%s" "$comm" | json_escape)

  [ $pfirst -eq 1 ] || printf ","
  printf '{"pid":%s,"ppid":%s,"cpu":%s,"pticks":%s,"memoryPercent":%s,"memoryKB":%s,"pssKB":%s,"pssPercent":%s,"command":"%s","fullCommand":"%s"}' \
  "$pid" "$ppid" "$cpu" "$pticks" "$pss_pct" "$rss_kib" "$pss_kib" "$pss_pct" "$comm_esc" "$cmd"
  pfirst=0
  done < "$tmp_ps"
  rm -f "$tmp_ps"
  printf '],'

  load_avg=$(cut -d' ' -f1-3 /proc/loadavg)
  proc_count=$(ls -Ud /proc/[0-9]* 2>/dev/null | wc -l)
  thread_count=$(ls -Ud /proc/[0-9]*/task/[0-9]* 2>/dev/null | wc -l)
  boot_time=$(who -b 2>/dev/null | awk '{print $3, $4}' | json_escape || echo 'Unknown')

  printf '"system":{"loadavg":"%s","processes":%d,"threads":%d,"boottime":"%s"},' \\
  "$load_avg" "$proc_count" "$thread_count" "$boot_time"

  printf '"diskmounts":['
  tmp_mounts=$(mktemp)
  df -h --output=source,target,fstype,size,used,avail,pcent | tail -n +2 | grep -vE '^(tmpfs|devtmpfs)' | head -n 10 > "$tmp_mounts" || true
  mfirst=1
  while IFS= read -r line; do
  [ -z "$line" ] && continue
  device=$(echo "$line" | awk '{print $1}' | json_escape)
  mount=$(echo "$line" | awk '{print $2}' | json_escape)
  fstype=$(echo "$line" | awk '{print $3}')
  size=$(echo "$line" | awk '{print $4}')
  used=$(echo "$line" | awk '{print $5}')
  avail=$(echo "$line" | awk '{print $6}')
  percent=$(echo "$line" | awk '{print $7}')
  [ $mfirst -eq 1 ] || printf ","
  printf '{"device":"%s","mount":"%s","fstype":"%s","size":"%s","used":"%s","avail":"%s","percent":"%s"}' \\
  "$device" "$mount" "$fstype" "$size" "$used" "$avail" "$percent"
  mfirst=0
  done < "$tmp_mounts"
  rm -f "$tmp_mounts"
  printf ']',

  printf '"gputemps":['
  gfirst=1
  tmp_gpu=$(mktemp)

  # Gather GPU temperatures only
  for card in /sys/class/drm/card*; do
  [ -e "$card/device/driver" ] || continue

  drv=$(basename "$(readlink -f "$card/device/driver")")
  drv=\${drv##*/}

  # Temperature
  hw=""; temp="0"
  for h in "$card/device"/hwmon/hwmon*; do
  [ -e "$h/temp1_input" ] || continue
  hw=$(basename "$h")
  temp=$(awk '{printf "%.1f",$1/1000}' "$h/temp1_input" 2>/dev/null || echo "0")
  break
  done

  # NVIDIA temperature fallback
  if [ "$drv" = "nvidia" ] && [ "$temp" = "0" ] && command -v nvidia-smi >/dev/null 2>&1; then
  t=$(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits 2>/dev/null | head -1)
  [ -n "$t" ] && { temp="$t"; hw="\${hw:-nvidia}"; }
  fi

  [ "$temp" != "0" ] && {
  [ $gfirst -eq 1 ] || printf ","
  printf '{"driver":"%s","hwmon":"%s","temperature":%s}' "$drv" "\${hw:-unknown}" "\${temp:-0}"
  gfirst=0
  }
  done

  # Fallback if no DRM cards found but nvidia-smi is available
  if [ $gfirst -eq 1 ]; then
  if command -v nvidia-smi >/dev/null 2>&1; then
  temp=$(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits 2>/dev/null | head -1)
  [ -n "$temp" ] && {
  printf '{"driver":"nvidia","hwmon":"nvidia","temperature":%s}' "$temp"
  gfirst=0
  }
  fi
  fi

  rm -f "$tmp_gpu"
  printf ']'

  printf "}\\n"`

  Process {
    id: staticDataProcess
    command: ["bash", "-c", "bash -s <<'QS_EOF'\n"
      + root.staticDataScript + "\nQS_EOF\n"]
    running: false
    onExited: exitCode => {
      if (exitCode !== 0) {
        console.warn("Static data collection failed with exit code:", exitCode)
      }
    }
    stdout: StdioCollector {
      onStreamFinished: {
        if (text.trim()) {
          const fullText = text.trim()
          const lastBraceIndex = fullText.lastIndexOf('}')
          if (lastBraceIndex === -1) {
            console.warn("Invalid static data JSON")
            return
          }
          const jsonText = fullText.substring(0, lastBraceIndex + 1)

          try {
            const data = JSON.parse(jsonText)
            parseStaticData(data)
          } catch (e) {
            console.warn("Failed to parse static data JSON:", e)
            return
          }
        }
      }
    }
  }

  Process {
    id: dynamicStatsProcess
    command: ["bash", "-c", "bash -s \"$1\" \"$2\" <<'QS_EOF'\n"
      + root.dynamicDataScript + "\nQS_EOF\n", root.sortBy, String(root.maxProcesses)]
    running: false
    onExited: exitCode => {
      if (exitCode !== 0) {
        isUpdating = false
      }
    }
    stdout: StdioCollector {
      onStreamFinished: {
        if (text.trim()) {
          const fullText = text.trim()
          const lastBraceIndex = fullText.lastIndexOf('}')
          if (lastBraceIndex === -1) {
            isUpdating = false
            return
          }
          const jsonText = fullText.substring(0, lastBraceIndex + 1)

          try {
            const data = JSON.parse(jsonText)
            parseDynamicStats(data)
          } catch (e) {
            isUpdating = false
            return
          }
        }
      }
    }
  }
}
