VERSION=4.1.1-2

build:
	docker login
	docker build --no-cache -t mytidyverse .
	docker tag mytidyverse paulklemm/mytidyverse:base-$(VERSION)
	docker push paulklemm/mytidyverse:base-$(VERSION)
