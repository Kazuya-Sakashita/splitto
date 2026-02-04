.PHONY: openapi-lint openapi-ui

openapi-lint:
	docker run --rm -v "$(PWD):/work" -w /work node:20 \
	  sh -lc "npx -y @redocly/cli lint --config openapi/.redocly.yaml openapi/openapi.yaml"

openapi-ui:
	docker run --rm -p 8081:8080 \
	  -e SWAGGER_JSON=/openapi/openapi.yaml \
	  -v "$(PWD)/openapi:/openapi" \
	  swaggerapi/swagger-ui
