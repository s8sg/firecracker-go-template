# firecracker-go-template
Builds firecracker filesystem with provided Go application   
   
> This repository is a direct copy and edit on **UNIK's firecracker compiler**  
> For more details on UNIK click [here](https://github.com/solo-io/unik)  
  
  
## Getting Started
   
**Prerequisites**
```text
docker
firecracker
firectl
```
Get firecracker kernel
```bash
curl -fsSL -o /tmp/hello-vmlinux.bin https://s3.amazonaws.com/spec.ccfc.min/img/hello/kernel/hello-vmlinux.bin
```


**Setup tap interface - Optional for network**
```bash
sudo ip tuntap add tap0 mode tap # user $(id -u) group $(id -g)
sudo ip addr add 172.20.0.1/24 dev tap0
sudo ip link set tap0 up
```
Set your main interface device. If you have different name check it with ifconfig command
```bash
DEVICE_NAME=eth0
```
Provide iptables rules to enable packet forwarding
```bash
sudo sh -c "echo 1 > /proc/sys/net/ipv4/ip_forward"
sudo iptables -t nat -A POSTROUTING -o $DEVICE_NAME -j MASQUERADE
sudo iptables -A FORWARD -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
sudo iptables -A FORWARD -i tap0 -o $DEVICE_NAME -j ACCEPT
```
   
### Build docker image
```bash
make
```

### Write your simple golang application  
   
##### 1. Write your demo go application
```bash
mkdir demo
cat > demo/main.go <<EOF
package main

import (
  "fmt"
  "os/exec"
  "time"
)

func main() {
  for {
    fmt.Println("Hello from firecracker (run by unik from solo.io)")
    out, _ := exec.Command("uname", "-a").CombinedOutput()
    fmt.Printf("OS Version: %s\n", string(out))
    time.Sleep(10 * time.Second)
  }
}
EOF
```
    
##### 2. Build root filesystem using `build` script
```bash
./build ./demo my_root_fs
```
   
##### 3. Use `firectl` to run firecracker with your rootfs
```bash
ROOTFS="$(readlink -f my_root_fs)"
sudo firectl \
   --kernel=/tmp/hello-vmlinux.bin \
   --root-drive=$ROOTFS \ 
   --kernel-opts="console=ttyS0 noapic reboot=k panic=1 pci=off nomodules rw" 
```
    
### Write your golang Http Server (need tap device setup)
##### 1. Write your demo go application
```bash
mkdir demo
cat > demo/main.go <<EOF
package main

import (
    "fmt"
    "log"
    "net/http"
)

func handler(w http.ResponseWriter, r *http.Request) {
    fmt.Fprintf(w, "Hi there, I love %s!", r.URL.Path[1:])
}

func main() {
    http.HandleFunc("/", handler)
    log.Fatal(http.ListenAndServe(":8080", nil))
}
EOF
```
    
##### 2. Build root filesystem using `build` script
```bash
./build ./demo my_root_fs 172.20.0.2/24 172.20.0.1
```
   
#### 3. Use `firectl` to run firecracker with your rootfs
```bash
MAC="$(cat /sys/class/net/tap0/address)"
ROOTFS="$(readlink -f my_root_fs)"
sudo firectl \
   --kernel=/tmp/hello-vmlinux.bin \
   --root-drive=$ROOTFS \ 
   --kernel-opts="console=ttyS0 noapic reboot=k panic=1 pci=off nomodules rw" \ 
   --tap-device=tap0/$MAC
```

#### 4. Test your application server
```bash
curl http://172.20.0.2:8080/firecracker
```
