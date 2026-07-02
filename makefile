VERSION=4.6.1-1
DOCKERHUB_USER=paulklemm
SERVER=pklemm@blade44.sf.mpg.de
SINGULARITY_PATH=/cephfs/scratch/bruening_scratch/pklemm/singularity/singularity-images
SINGULARITY_LATEST_PATH=$(SINGULARITY_PATH)/latest
PLATFORM=--platform linux/amd64
SINGULARITY_IMAGE=quay.io/singularity/singularity:v4.3.1

.PHONY: all build singularity copy create-link clean
all: build singularity copy create-link clean

build:
	docker login
	docker build --pull $(PLATFORM) -t mytidyverse .
	docker tag mytidyverse $(DOCKERHUB_USER)/mytidyverse:$(VERSION)
	docker push $(DOCKERHUB_USER)/mytidyverse:$(VERSION)

singularity:
	docker run $(PLATFORM) --rm -v "$(CURDIR):/mytidyverse" $(SINGULARITY_IMAGE) build /mytidyverse/mytidyverse-$(VERSION).simg docker://$(DOCKERHUB_USER)/mytidyverse:$(VERSION)

copy:
	scp "$(CURDIR)/mytidyverse-$(VERSION).simg" $(SERVER):$(SINGULARITY_PATH)

create-link:
	ssh $(SERVER) "ln -sfn $(SINGULARITY_PATH)/mytidyverse-$(VERSION).simg $(SINGULARITY_LATEST_PATH)/mytidyverse.simg"

clean:
	rm -f mytidyverse-$(VERSION).simg
