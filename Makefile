dev:
	circleci orb pack src --skip-update-check > orb.yml
	circleci orb publish --skip-update-check "orb.yml" "dafiti-group/orb-standard-pipeline@dev:first"
