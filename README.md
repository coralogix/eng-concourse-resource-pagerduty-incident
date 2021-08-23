# eng-concourse-resource-pagerduty-incident
A resource type for Concourse CI which creates a PagerDuty incident.

Lightly adapted from the PagerDuty documentation of the [REST API](https://developer.pagerduty.com/api-reference/reference/REST/openapiv3.json/paths/~1incidents/post) and the [Events v2 API](https://developer.pagerduty.com/docs/events-api-v2/overview/)

## Source Configuration
You are required to configure the resource either as targeting the REST API or as targeting the Events v2 API.

Do note that the REST API is *synchronous* while the Events v2 API is *asynchronous*. This means that, if you use the
Events v2 API, Concourse will not wait until the event has triggered an incident in PagerDuty, but that if you use the
REST API, the API waits until after the incident has been created and as such Concourse will wait until after the incident is
created to proceed.

### REST API
* `rest1.api_key` : _Required_ (`string`). The PagerDuty API key to use.
* `rest.from_pagerduty_user` : _Required_ (`string`). The email address of a PagerDuty user
                               in whose name this Concourse resource is reporting the incident.
* `rest.autogenerate_incident_key`: _Optional_ (`bool`). If true, the resource will set the
                                    `incident_key` to the Concourse build URL. Defaults to
                                    `true`.
* `rest.include_build_link` : _Optional_ (`bool`). If true, the resource will append a link
                              to the build in the body of the incident before sending it to
                              the PagerDuty API. Defaults to `true`.

### Events v2 API
* `events_v2.routing_key`: _Required_ (`string`). The routing key for the PagerDuty Events V2 API integration.
* `events_v2.client`: _Optional_ (`string`). When triggering alerts, the client to attach to the payload. Defaults to `Concourse`.
* `events_v2.client_url`: _Optional_ (`string`). When triggering alerts, the client URL to attach to the payload. Defaults to `$ATC_EXTERNAL_URL`.
* `events_v2.attach_build_url_to_links`: _Optional_ (`bool`). If true, the resource will attach a link to the
                                         build in the payload's links section. Defaults to `true`.
* `events_v2.attach_timestamp`: _Optional_ (`bool`). If true, and if a timestamp is not provided in the 
                                put parameters, the resource will call `date` to get a timestamp
                                and attach the timestamp to the payload. If this is false and no timestamp
                                is provided, then PagerDuty will apply a default timestamp when PagerDuty receives
                                the payload. Defaults to `true`.

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

Resource configuration (REST API)

```yaml
resources:
  - name: pagerduty-incident
    type: pagerduty-incident
    source:
      rest:
        api_key: (( pagerduty.api_key ))
        from_pagerduty_user: me@example.com
```

Resource configuration (Events v2 API)

```yaml
resources:
  - name: pagerduty-incident
    type: pagerduty-incident
    source:
      events_v2:
        routing_key: ((pagerduty.routing_key))
        attach_timestamp: true
```

## Behavior

### `check` : Not supported

### `in` : Not supported

### `out` : Create a PagerDuty Incident
Create an incident or push an event to PagerDuty.

#### Params (REST API)
* `incident` : _Required_ (`incident`). The incident to be created. To understand how to
               populate this object, please refer to the PagerDuty documentation.

#### Params (Events v2 API)
* `event_type`: _Optional_ (`enum`). Must be either `alert` or `change`. Defaults to `alert`.
* `event_action`: _Optional_ (`enum`). For alerts, must be either `trigger`, `acknowledge`, or `resolve`.
                  Defaults to `trigger`.
* `dedup_key`: _Optional_ (`string`). The deduplication key. Defaults to the build URL (i.e. `$ATC_EXTERNAL_URL/builds/$BUILD_ID`).
* `summary`: _Optional_ (`string`). The event's summary. Required, unless this is an `alert` event of action `acknowledge` or `resolve`.
* `source`: _Optional_ (`string`). The event's source. Required if this is an `alert` event of action `trigger`.
* `severity`: _Optional_ (`string`). The event's severity. Required if this is an `alert` event of action `trigger`.
* `source`: _Optional_ (`string`). The event's source.
* `timestamp`: _Optional_ (`ISO-8601 timestamp`). The event's timestamp. You would presumably use this field in a pipeline configuration
               by populating the field with a timestamp created in an earlier step with the help of Concourse's `load_var`.
* `component`: _Optional_ (`string`). The event's component.
* `group`: _Optional_ (`string`). The event's group.
* `class`: _Optional_ (`string`). The event's class.
* `custom_details`: _Optional_ (`object`). The event's custom details.
* `custom_details_file`: _Optional_ (`file path`). A path to a JSON file with additional custom details, i.e. generated in a previous step.
* `images`: _Optional_ (`list(object({src: string, href: optional string, alt: optional string}))`). The event's images.
* `links`: _Optional_ (`list(object({href: string, text: optional string}))`). The event's links.

### Example Usage
Used in `on_abort`, `on_error`, and `on_failed` to alert a pipeline owner that the
pipeline has failed.

#### REST API
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
      rest:
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

#### Events v2 API
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
      events_v2:
        routing_key: (( pagerduty.api_key ))

jobs:
  - name: my-critical-job
    plan:
      - put: pagerduty-incident
        params:
          event_type: change
          summary: "About to try a critical task"
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
            summary: "My pipeline's critical task failed!"
            source: "Concourse Pipeline"
            severity: critical
```

## Maintainers
* [Ari Becker](https://github.com/ari-becker)
* [Oded David](https://github.com/oded-dd)
* [Amit Oren](https://github.com/amit-o)
* [Shauli Solomovich](https://github.com/ShauliSolomovich)

## License
[Apache License 2.0](https://www.apache.org/licenses/LICENSE-2.0) © Coralogix, Inc.
