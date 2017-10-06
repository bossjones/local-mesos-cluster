# local-mesos-cluster
Quick setup to allow anyone to bring up a local mesos/marathon environment using docker-compose.


# config

`~/.local-mesos-cluster/config.json`

```
  "github": {
        "auth": {
            "token": "your_oauth_token"
        },
        "orgs": [
            "behanceops"
        ]
    },
    "jenkins": {
        "instances": {
            "bejankins": {
                "jenkins": {
                    "url": "http://bejankins.net:8080",
                    "user": "behance-qe",
                    "password": "password"
                },
                "job_builder": {
                    "ignore_cache": "true"
                }
            }
        },
        "template_params": {
            "bejankins": {
                "gitauth": "aaaaaaaa-0000-aaaa-0000-aaaaaaaaaaaa",
                "ghprauth": "00000000-aaaa-0000-aaaa-000000000000"
            }
        },
        "jobs": [
            {
                "instance": "ci-jenkins",
                "owner": "behanceops",
                "repo": "bephp",
                "templates": [
                    "{repo}-integrations"
                ]
            },
            {
                "instance": "bejankins",
                "owner": "behanceops",
                "templates": [
                    "branch-cookbook-{repo}",
                    "master-cookbook-{repo}"
                ],
                "exclude": [
                    "misc"
                ]
            }
        ]
    }
}
```
