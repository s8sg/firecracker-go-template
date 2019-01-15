# firecracker-go-template
Builds firecracker filesystem with provided Go application   
   
> This repository is a direct copy and edit on **UNIK's firecracker compiler**  
> For more details on UNIK click [here](https://github.com/solo-io/unik)  
  
  
## Getting Started
   
Prerequisites
```text
docker
```
   
#### 1. Build docker image
```bash
make
```
   
#### 2. Write your simple demo golang Application
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
    
#### 3. Build root filesystem using `build` script
```bash
./build ./demo my_root_fs
```
   
#### 4. Get firecracker kernel
```bash
curl -fsSL -o /tmp/hello-vmlinux.bin https://s3.amazonaws.com/spec.ccfc.min/img/hello/kernel/hello-vmlinux.bin
```
   
#### 5. Use `firectl` to run firecracker with your rootfs
```bash
ROOTFS="$(readlink -f my_root_fs)"
sudo firectl   --kernel=/home/vanu/hello-vmlinux.bin   --root-drive=$ROOTFS   --kernel-opts="console=ttyS0 noapic reboot=k panic=1 pci=off nomodules rw"
```
