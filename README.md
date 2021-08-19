# eng-concourse-resource-pagerduty-incident
A resource type for Concourse CI which creates a PagerDuty incident.

Lightly adapted from the [PagerDuty documentation](https://developer.pagerduty.com/api-reference/reference/REST/openapiv3.json/paths/~1incidents/post).

## Source Configuration
* `api_key` : _Required_ (`string`). The PagerDuty API key to use.
* `from_pagerduty_user` : _Required_ (`string`). The email address of a PagerDuty user
                          in whose name this Concourse resource is reporting the incident.
* `autogenerate_incident_key`: _Optional_ (`bool`). If true, the resource will set the
                               `incident_key` to the Concourse build URL. Defaults to
                               `true`.
* `include_build_link` : _Optional_ (`bool`). If true, the resource will append a link
                         to the build in the body of the incident before sending it to
                         the PagerDuty API. Defaults to `true`.

### Example Configuration

Resource type definition

```yaml
resource_types:
  - name: pagerduty-incident
    type: registry-image
    source:
      repository: ghcr.io/coralogix/eng-concourse-resource-pagerduty-incident
      tag: v0.1.0
```

Resource configuration

```yaml
resources:
  - name: pagerduty-incident
    type: pagerduty-incident
    source:
      api_key: (( pagerduty.api_key ))
      from_pagerduty_user: me@example.com
```

## Behavior

### `check` : Not supported

### `in` : Not supported

### `out` : Create a PagerDuty Incident
Create an incident in PagerDuty.

#### Params
* `incident` : _Required_ (`incident`). The incident to be created. To understand how to
               populate this object, please refer to the PagerDuty documentation.

### Example Usage

Used in `on_abort`, `on_error`, and `on_failed` to alert a pipeline owner that the
pipeline has failed.

```yaml
resource_types:
  - name: pagerduty-incident
    type: registry-image
    source:
      repository: ghcr.io/coralogix/eng-concourse-resource-pagerduty-incident
      tag: v0.1.0

resources:
  - name: pagerduty-incident
    type: pagerduty-incident
    source:
      api_key: (( pagerduty.api_key ))
      from_pagerduty_user: me@example.com

jobs:
  - name: my-critical-job
    plan:
      - task: critical-task
        config:
          platform: linux
          image_resource:
            type: registry-image
            source: { repository: busybox }
          run:
            path: /bin/sh
            args:
              - '-c'
              - 'echo "Oops, my critical task failed!" ; exit 1'
        on_failure:
          put: pagerduty-incident
          params:
            incident:
              type: incident
              title: "My pipeline's critical task failed!"
              service:
                # id is the PagerDuty service ID
                id: P12345
                type: service_reference
              urgency: high
              body:
                type: incident_body
                details: "The pipeline's critical task failed, you should check why!"
              escalation_policy:
                # id is the PagerDuty escalation policy ID
                id: P12345
                type: escalation_policy_reference
```

## Maintainers
* [Ari Becker](https://github.com/ari-becker)
* [Oded David](https://github.com/oded-dd)
* [Amit Oren](https://github.com/amit-o)
* [Shauli Solomovich](https://github.com/ShauliSolomovich)

## License
[Apache License 2.0](https://www.apache.org/licenses/LICENSE-2.0) © Coralogix, Inc.
