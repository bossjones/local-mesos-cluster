# local-mesos-cluster
Quick setup to allow anyone to bring up a local mesos/marathon environment using docker-compose.


# config

`~/.local-mesos-cluster/config.json`

```
  "local-mesos-cluster": {
    "docker-machines": {
        "instances": {
            "local-mesos-cluster": {
                "docker": {
                    "tls_verify": "1",
                    "host": "tcp://192.168.99.101:2376",
                    "cert_path": "/Users/user/.docker/machine/machines/local-mesos-cluster",
                    "machine_name": "local-mesos-cluster"
                }
            }
        }
    }
}
```
