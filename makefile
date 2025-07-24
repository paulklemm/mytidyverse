VERSION=4.5.1-1
DOCKERHUB_USER=paulklemm
SERVER=pklemm@blade27.sf.mpg.de
SINGULARITY_PATH=/beegfs/scratch/bruening_scratch/pklemm/singularity/singularity-images
SINGULARITY_LATEST_PATH=$(SINGULARITY_PATH)/latest
PLATFORM=--platform linux/amd64
SINGULARITY_IMAGE=quay.io/singularity/singularity:v4.1.0

.PHONY: all
all: build singularity copy create-link clean

build:
	docker login
	docker build $(PLATFORM) -t mytidyverse .
	docker tag mytidyverse $(DOCKERHUB_USER)/mytidyverse:$(VERSION)
	docker push $(DOCKERHUB_USER)/mytidyverse:$(VERSION)

singularity:
	docker run $(PLATFORM) --rm -v "${PWD}:/mytidyverse" -it $(SINGULARITY_IMAGE) build /mytidyverse/mytidyverse-$(VERSION).simg docker://paulklemm/mytidyverse:$(VERSION)

copy:
	scp "${PWD}/mytidyverse-$(VERSION).simg" $(SERVER):$(SINGULARITY_PATH)

create-link:
	ssh $(SERVER) "rm $(SINGULARITY_LATEST_PATH)/mytidyverse.simg; ln -s $(SINGULARITY_PATH)/mytidyverse-$(VERSION).simg $(SINGULARITY_LATEST_PATH)/mytidyverse.simg"

clean:
	rm -f mytidyverse-$(VERSION).simg
