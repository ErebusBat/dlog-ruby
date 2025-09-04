export DLOG_SLEEP?=5
export DLOG_WAIT?=10
VER?=latest
TAG=erebusbat/dlog-fixup:$(VER)

irb:
	irb -r./lib/init.rb

build_dev:
	docker build . --tag=$(TAG)

build: build_linux build_darwin

build_linux:
	docker build . --tag=$(TAG) --platform=linux/amd64

build_darwin:
	docker build . --tag=$(TAG) --platform=darwin

publish: build_linux push

push:
	docker push $(TAG)

up:
	docker compose up --force-recreate

down:
	docker compose down

rm:
	docker image rm $(TAG)

rmf:
	docker image rm -f $(TAG)
