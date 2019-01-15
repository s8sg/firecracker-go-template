all: clean
	echo "Building go template"
	docker build -t s8sg/firecracker-go-template:0.1.0 ./template

clean:
	docker rmi s8sg/firecracker-go-template:0.1.0
