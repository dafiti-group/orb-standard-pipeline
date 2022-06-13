pack:
	circleci orb pack src --skip-update-check > orb.yml
validate:
	circleci orb validate orb.yml
dev: pack validate
	circleci orb publish --skip-update-check "orb.yml" "dafiti-group/orb-standard-pipeline@dev:first"
