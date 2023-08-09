remove_old:
	rm orb.yml || exit 0

pack: remove_old
	circleci orb pack src --skip-update-check > orb.yml

validate: pack
	circleci orb validate orb.yml

dev: pack validate
	circleci orb publish --skip-update-check "orb.yml" "dafiti-group/orb-standard-pipeline@dev:checkmarx"
