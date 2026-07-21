VERSION=4.6.1-1
DOCKERHUB_USER=paulklemm
SERVER=pklemm@blade44.sf.mpg.de
SINGULARITY_PATH=/cephfs/scratch/bruening_scratch/pklemm/singularity/singularity-images
SINGULARITY_LATEST_PATH=$(SINGULARITY_PATH)/latest
PLATFORM=--platform linux/amd64
SINGULARITY_IMAGE=quay.io/singularity/singularity:v4.3.1

# --- R package migration (run around an R minor-version bump) ----------------
# R uses a per-minor-version library, so bumping 4.5 -> 4.6 needs every package
# reinstalled. These targets run pak-migrate.R inside the image, on the server,
# where the ~/R libraries live. Extra flags: `make restore PAK_FLAGS=--upgrade`.
MIGRATE_SCRIPT=pak-migrate.R
MANIFEST=r-package-manifest.csv
REMOTE_MIGRATE_PATH=$(SINGULARITY_PATH)
# Image to READ from when snapshotting: whatever is live now (the old R).
CURRENT_IMAGE=$(SINGULARITY_LATEST_PATH)/mytidyverse.simg
# Image to REINSTALL into: this build's versioned .simg (present after `copy`).
NEW_IMAGE=$(SINGULARITY_PATH)/mytidyverse-$(VERSION).simg
SEXEC=cd $(REMOTE_MIGRATE_PATH) && singularity exec

.PHONY: all build singularity copy create-link clean push-migrate snapshot restore-dry restore verify
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

# Copy the migration script to the server (prerequisite for the targets below).
push-migrate:
	scp "$(CURDIR)/$(MIGRATE_SCRIPT)" $(SERVER):$(REMOTE_MIGRATE_PATH)/

# 1. BEFORE going live: capture the packages installed under the current image.
snapshot: push-migrate
	ssh $(SERVER) "$(SEXEC) $(CURRENT_IMAGE) Rscript $(MIGRATE_SCRIPT) snapshot $(MANIFEST)"

# 2a. Preview what would be reinstalled under the new image. Installs nothing.
restore-dry: push-migrate
	ssh $(SERVER) "$(SEXEC) $(NEW_IMAGE) Rscript $(MIGRATE_SCRIPT) restore $(MANIFEST) --dry-run"

# 2b. Reinstall the manifest under the new image with pak.
restore: push-migrate
	ssh $(SERVER) "$(SEXEC) $(NEW_IMAGE) Rscript $(MIGRATE_SCRIPT) restore $(MANIFEST) $(PAK_FLAGS)"

# 3. Verify the new library matches the manifest before flipping `latest`.
verify: push-migrate
	ssh $(SERVER) "$(SEXEC) $(NEW_IMAGE) Rscript $(MIGRATE_SCRIPT) verify $(MANIFEST)"
