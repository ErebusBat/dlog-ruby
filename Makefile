VER?=latest
TAG=erebusbat/dlog-fixup:$(VER)

build:
	docker build . --tag=$(TAG)

push:
	docker push $(TAG)
