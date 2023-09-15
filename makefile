VERSION=4.3.1-3

build:
	docker login
	docker build --platform linux/x86_64 -t mytidyverse .
	docker tag mytidyverse paulklemm/mytidyverse:$(VERSION)
	docker push paulklemm/mytidyverse:$(VERSION)
