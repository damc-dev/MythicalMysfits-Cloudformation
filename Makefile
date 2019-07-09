#!/usr/bin/make -f

STACK_NAME ?= mythical-mysfits
AWS_DEFAULT_REGION ?= us-west-2
DEPLOY_ENV_TARGET ?= dev

depoy: deploy-cfn-vpc \
	deploy-cfn-static-site \
	wait-cfn-static-site \
	upload-static-site \
	wait-cfn-vpc \
	
update: update-cfn-vpc \
	update-cfn-static-site

delete: delete-cfn-static-site \
	delete-cfn-vpc

deploy-cfn-%: params/${DEPLOY_ENV_TARGET}/${AWS_DEFAULT_REGION}/%.json templates/%.cfn.yml
	$(info --- $@ to ${DEPLOY_ENV_TARGET} in ${AWS_DEFAULT_REGION})
	@aws --region $(AWS_DEFAULT_REGION) cloudformation create-stack \
	--stack-name ${STACK_NAME}-$(patsubst deploy-cfn-%,%,$@) \
	--template-body file://$(word 2,$^) \
	--parameters file://$< \
	--capabilities CAPABILITY_IAM CAPABILITY_AUTO_EXPAND

describe-cfn-%:
	$(info --- $@ to ${DEPLOY_ENV_TARGET} in ${AWS_DEFAULT_REGION})
	@aws --region $(AWS_DEFAULT_REGION) cloudformation describe-stacks \
	--stack-name ${STACK_NAME}-$(patsubst describe-cfn-%,%,$@)
	
wait-cfn-%:
	$(info --- $@ to ${DEPLOY_ENV_TARGET} in ${AWS_DEFAULT_REGION})
	@aws --region $(AWS_DEFAULT_REGION) cloudformation wait stack-create-complete \
	--stack-name ${STACK_NAME}-$(patsubst wait-cfn-%,%,$@)
	
update-cfn-%: params/${DEPLOY_ENV_TARGET}/${AWS_DEFAULT_REGION}/%.json templates/%.cfn.yml
	$(info --- $@ to ${DEPLOY_ENV_TARGET} in ${AWS_DEFAULT_REGION})
	@aws --region $(AWS_DEFAULT_REGION) cloudformation update-stack \
	--stack-name ${STACK_NAME}-$(patsubst update-cfn-%,%,$@) \
	--template-body file://$(word 2,$^) \
	--parameters file://$< \
	--capabilities CAPABILITY_IAM CAPABILITY_AUTO_EXPAND

delete-cfn-%:
	$(info --- $@ to ${DEPLOY_ENV_TARGET} in ${AWS_DEFAULT_REGION})
	@aws --region $(AWS_DEFAULT_REGION) cloudformation delete-stack --stack-name $(STACK_NAME)-$(patsubst delete-cfn-%,%,$@)

upload-static-site:
	$(info --- $@ to ${DEPLOY_ENV_TARGET} in ${AWS_DEFAULT_REGION})
	@aws s3 cp static-site/index.html s3://$(AWS_DEFAULT_REGION)-$(STACK_NAME)-static-site/index.html

.PHONY: create-bucket
create-bucket:
	@aws s3 mb "$(CFN_BUCKET)"

.PHONY: validate-templates
validate-templates:
	chmod a+x ./tests/validate-templates.sh
	./tests/validate-templates.sh