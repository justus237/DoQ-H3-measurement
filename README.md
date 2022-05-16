# DoQ-H3-measurement

## iperf testing to find a decent simulation for 4G:
### 50Mbps download 10Mbps upload 0.11% symmetric packet loss 110ms symmetric RTT
```
tbf(throughput)+netem(delay)+iptables(loss):
20s upload: 
[ ID] Interval           Transfer     Bitrate         Retr
[  5]   0.00-20.00  sec  31.2 MBytes  13.1 Mbits/sec   18             sender
[  5]   0.00-20.12  sec  22.6 MBytes  9.42 Mbits/sec                  receiver
20s download:
[ ID] Interval           Transfer     Bitrate         Retr
[  5]   0.00-20.11  sec  72.5 MBytes  30.2 Mbits/sec   36             sender
[  5]   0.00-20.00  sec  63.7 MBytes  26.7 Mbits/sec                  receiver

tbf(throughput)+netem(delay+loss):
20s upload:
[ ID] Interval           Transfer     Bitrate         Retr
[  5]   0.00-20.00  sec  26.2 MBytes  11.0 Mbits/sec   26             sender
[  5]   0.00-20.11  sec  17.8 MBytes  7.43 Mbits/sec                  receiver
20s download:
[ ID] Interval           Transfer     Bitrate         Retr
[  5]   0.00-20.11  sec  43.8 MBytes  18.2 Mbits/sec   43             sender
[  5]   0.00-20.00  sec  35.2 MBytes  14.8 Mbits/sec                  receiver

netem(throughput+delay+loss):
20s upload:
[ ID] Interval           Transfer     Bitrate         Retr
[  5]   0.00-20.00  sec  26.2 MBytes  11.0 Mbits/sec   17             sender
[  5]   0.00-20.14  sec  18.0 MBytes  7.49 Mbits/sec                  receiver
20s download:
[ ID] Interval           Transfer     Bitrate         Retr
[  5]   0.00-20.11  sec  33.8 MBytes  14.1 Mbits/sec   36             sender
[  5]   0.00-20.00  sec  25.3 MBytes  10.6 Mbits/sec                  receiver
```