# docker-compose and overrides

*source: https://docs.docker.com/compose/extends/#adding-and-overriding-configuration*
*source:https://docs.docker.com/compose/extends/#example-use-case*
*source:https://docs.docker.com/compose/reference/overview/*

**Example: `docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d`**

```
Compose copies configurations from the original service over to the local one. If a configuration option is defined in both the original service and the local service, the local value replaces or extends the original value.

For single-value options like image, command or mem_limit, the new value replaces the old value.
```
