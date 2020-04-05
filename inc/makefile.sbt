sbt?=./sbt

sbt: ## Pull sbt script
	rm -rf ./sbt
	curl -o ./sbt -Ls https://git.io/sbt
	chmod +x ./sbt

sbt/clean: dep/sbt ## Clean test
	$(sbt) clean

sbt/update: ## Unit tests
	$(sbt) update

sbt/test: ## Unit tests
	$(sbt) test evicted

sbt/coverage: ## Coverage report
	$(sbt) coverage coverageReport

sbt/build: ## Build assembly (sbt)
	$(sbt) -no-colors \
		"set test in assembly := {}" \
		assembly

sbt/publish: ## Publish assembly (sbt)
	$(sbt) -no-colors \
		"set test in assembly := {}" \
		publish
