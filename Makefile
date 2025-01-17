SHELL := /bin/bash
KUBE_SUPPORTED_VERSIONS = 1.21.0 1.22.0 1.23.0 1.24.0 1.25.0 1.26.0

NAME=mender
VERSION=$$(grep version: $(NAME)/Chart.yaml | sed -e 's/.*: *//g' | sed -e 's/"//g')

help: ## Show this help
	@IFS=$$'\n' ; \
		help_lines=(`fgrep -h "##" $(MAKEFILE_LIST) | fgrep -v fgrep | sed -e 's/\\$$//'`); \
		for help_line in $${help_lines[@]}; do \
				IFS=$$'#' ; \
				help_split=($$help_line) ; \
				help_command=`echo $${help_split[0]} | sed -e 's/^ *//' -e 's/ *$$//'` ; \
				help_info=`echo $${help_split[2]} | sed -e 's/^ *//' -e 's/ *$$//'` ; \
				printf "%-30s %s\n" $$help_command $$help_info ; \
		done

.PHONY: clean
clean: ## Clean the working directory removing the packages and the rendered templates
	rm -fr $(NAME)-$(VERSION)*.tgz $(NAME)-$(VERSION)*.yaml index.yaml tmp.*

.PHONY: lint
lint: ## Lint the mender helm package
	helm lint -f examples/values-mender.yaml $(NAME)

.PHONY: package
package: ## Create the mender helm package
	helm package $(NAME)
	helm repo index --url https://charts.mender.io .

.PHONY: upload
upload: package ## Upload the mender helm package to the charts repository
	curl --data-binary "@$(NAME)-$(VERSION).tgz" http://charts.mender.io/api/charts

.PHONY: template
template: ## Render the mender helm chart template
	helm template $(NAME)/ -f values-enterprise.yaml > $(NAME)-$(VERSION).yaml

.PHONY: test
test: ## Run tests
	bash tests/tests.sh

.PHONY: kubeconform
kubeconform: ## Run kubeconform over helm chart rendered template
	for kubeversion in $(KUBE_SUPPORTED_VERSIONS); do \
		helm template $(NAME)/ -f values-enterprise.yaml --kube-version $$kubeversion | kubeconform --kubernetes-version $$kubeversion; \
	done
