VERSION=4.6.1-2
DOCKERHUB_USER=paulklemm
GITHUB_REPO=https://github.com/paulklemm/mytidyverse
SERVER=pklemm@blade44.sf.mpg.de
SINGULARITY_PATH=/cephfs/scratch/bruening_scratch/pklemm/singularity/singularity-images
SINGULARITY_LATEST_PATH=$(SINGULARITY_PATH)/latest
# Cache/tmp for the on-server `singularity pull` (keeps blobs off the home quota).
SINGULARITY_CACHE_DIR=/cephfs/scratch/bruening_scratch/pklemm/singularity/cache
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
# Image to REINSTALL into: this build's versioned .simg (present after `remote-singularity`).
NEW_IMAGE=$(SINGULARITY_PATH)/mytidyverse-$(VERSION).simg
SEXEC=cd $(REMOTE_MIGRATE_PATH) && singularity exec

.PHONY: all ci-build wait-image remote-singularity create-link \
	local-deploy local-build local-singularity local-copy clean \
	push-migrate snapshot restore-dry restore verify

# Default: remote deploy. GitHub Actions builds and pushes the image (the tag
# push triggers .github/workflows/build.yml), then the server converts it to a
# .simg with an unprivileged `singularity pull` - no local Docker daemon, no
# root on the HPC.
all: ci-build wait-image remote-singularity create-link

# Tag HEAD as $(VERSION) and push it; GitHub Actions builds, smoke-tests and
# pushes $(DOCKERHUB_USER)/mytidyverse:$(VERSION) to Docker Hub. To rebuild an
# existing version, use "Run workflow" on the Actions page instead.
ci-build:
	@git diff --quiet && git diff --cached --quiet || { echo "Working tree is dirty - commit first."; exit 1; }
	git push origin HEAD
	git tag $(VERSION)
	git push origin $(VERSION)
	@echo "CI build running: $(GITHUB_REPO)/actions"

# Block until the CI-built image appears on Docker Hub (~30-60 min; gives up
# after 90 min - check the Actions page if that happens).
wait-image:
	@echo "Waiting for $(DOCKERHUB_USER)/mytidyverse:$(VERSION) on Docker Hub ..."
	@i=0; until curl -sfo /dev/null https://hub.docker.com/v2/repositories/$(DOCKERHUB_USER)/mytidyverse/tags/$(VERSION); do \
		i=$$((i+1)); \
		if [ $$i -ge 90 ]; then echo "Gave up after 90 min - check $(GITHUB_REPO)/actions"; exit 1; fi; \
		echo "  $$(date +%H:%M:%S)  not there yet, retrying in 60 s"; \
		sleep 60; \
	done
	@echo "Image is on Docker Hub."

# Convert the Docker Hub image to a .simg directly on the server. Pulling a
# docker:// URI is unprivileged - only .def-file builds would need root.
remote-singularity:
	ssh $(SERVER) "mkdir -p $(SINGULARITY_CACHE_DIR) && SINGULARITY_CACHEDIR=$(SINGULARITY_CACHE_DIR) SINGULARITY_TMPDIR=$(SINGULARITY_CACHE_DIR) singularity pull --force $(SINGULARITY_PATH)/mytidyverse-$(VERSION).simg docker://$(DOCKERHUB_USER)/mytidyverse:$(VERSION)"

create-link:
	ssh $(SERVER) "ln -sfn $(SINGULARITY_PATH)/mytidyverse-$(VERSION).simg $(SINGULARITY_LATEST_PATH)/mytidyverse.simg"

# --- Local fallback (the old flow; needs a local Docker daemon) --------------
local-deploy: local-build local-singularity local-copy create-link clean

local-build:
	docker login
	docker build --pull $(PLATFORM) -t mytidyverse .
	docker tag mytidyverse $(DOCKERHUB_USER)/mytidyverse:$(VERSION)
	docker push $(DOCKERHUB_USER)/mytidyverse:$(VERSION)

local-singularity:
	docker run $(PLATFORM) --rm -v "$(CURDIR):/mytidyverse" $(SINGULARITY_IMAGE) build /mytidyverse/mytidyverse-$(VERSION).simg docker://$(DOCKERHUB_USER)/mytidyverse:$(VERSION)

local-copy:
	scp "$(CURDIR)/mytidyverse-$(VERSION).simg" $(SERVER):$(SINGULARITY_PATH)

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
