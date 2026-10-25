PODMAN   ?= podman
IMAGE    ?= localhost/dayz-server:latest
NAME     ?= dayz-server
VOLUME_PREFIX ?= dayz-server

RUN_FLAGS = --name $(NAME) --replace \
	--env-file .env \
	-p 2302-2306:2302-2306/udp \
	-p 27016:27016/udp \
	-v $(VOLUME_PREFIX)-files:/opt/dayz/server \
	-v $(VOLUME_PREFIX)-profiles:/opt/dayz/profiles \
	-v $(VOLUME_PREFIX)-home:/home/steam \
	-v ./config:/opt/dayz/config:ro,z \
	-v ./mods.txt:/opt/dayz/mods.txt:ro,z \
	--restart unless-stopped \
	--stop-timeout 60

.PHONY: build up down restart update logs shell status steam-login

build:
	$(PODMAN) build -f Containerfile -t $(IMAGE) .

up:
	$(PODMAN) run -d $(RUN_FLAGS) $(EXTRA_ENV) $(IMAGE)

down:
	-$(PODMAN) stop $(NAME)
	-$(PODMAN) rm $(NAME)

restart: down up

update: EXTRA_ENV=-e DAYZ_AUTO_UPDATE=1 -e DAYZ_VALIDATE=1
update: down up

logs:
	$(PODMAN) logs -f $(NAME)

shell:
	$(PODMAN) exec -it $(NAME) bash

status:
	$(PODMAN) ps -a --filter name=$(NAME)

# Interactive steamcmd shell for first-time Steam Guard approval.
# Run `steamcmd +login $STEAM_USERNAME $STEAM_PASSWORD` inside, enter the
# guard code, then `quit`. The session is cached in the -home volume.
steam-login: build
	$(PODMAN) run --rm -it --env-file .env \
		-v $(VOLUME_PREFIX)-home:/home/steam:z \
		--entrypoint /bin/bash $(IMAGE)
