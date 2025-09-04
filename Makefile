export DLOG_SLEEP?=5
export DLOG_WAIT?=10
VER?=latest
TAG=erebusbat/dlog-fixup:$(VER)

build:
	docker build . --tag=$(TAG)

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
