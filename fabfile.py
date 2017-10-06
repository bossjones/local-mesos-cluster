#!/usr/bin/env python
# -*- coding: utf-8 -*-

# pylint: disable=invalid-name

import argparse
import datetime
import json
import logging
import math
import multiprocessing as mp
import os
import pprint
import re
import shutil
import sys
import time
from datetime import timezone

import fabric
import prettytable
import requests
from fabric import colors, tasks
from fabric.api import (abort, cd, env, get, hide, hosts, local, prefix,
                        prompt, put, require, roles, run, runs_once, settings,
                        show, sudo, warn, task, serial)
from fabric.contrib.project import rsync_project, upload_project
from fabric.operations import os as fos
from fabric.operations import sudo

from config import Config, NullConfig

# Set Timezone to UTC!
os.environ['TZ'] = 'UTC'
time.tzset()

FABRIC_KEY_FILENAME = os.path.expanduser(os.environ['PATH_TO_SSH_KEY'])
FABRIC_USER = os.getenv('FABRIC_USER', default='docker')

env.remote_interrupt = True
env.use_ssh_config = False
env.disable_known_hosts = True
env.forward_agent = True
env.keepalive = 120
env.key_filename = FABRIC_KEY_FILENAME
env.parallel = False
env.user = FABRIC_USER
env.abort_on_prompts = True
env.sudo_prefix = 'sudo -S '
env.shell= '/bin/sh -l -c'

# export DOCKER_TLS_VERIFY="1"
# export DOCKER_HOST="tcp://192.168.99.101:2376"
# export DOCKER_CERT_PATH="/Users/username/.docker/machine/machines/local-mesos-cluster"
# export DOCKER_MACHINE_NAME="local-mesos-cluster"
# # Run this command to configure your shell:
# # eval $(docker-machine env local-mesos-cluster)

# def bootstrap_env_vars():


def check_environment_vars_set():
    assert os.environ["PATH_TO_SSH_KEY"] != ""
    assert os.environ["FABRIC_USER"] != ""

def ssh_cert_path():
    try:
        return os.path.join(os.environ["DOCKER_CERT_PATH"], "id_rsa")
    except KeyError:
        raise "DOCKER_CERT_PATH environment variable not set?"

def app_home():
    try:
        return os.path.join(os.environ["HOME"], ".local-mesos-cluster")
    except KeyError:
        raise "HOME environment variable not set?"


def mkdir_if_dne(target):
    if not os.path.isdir(target):
        os.makedirs(target)


def prep_default_config():
    home = app_home()
    if not os.path.exists(home):
        os.makedirs(home)
    default_cfg = os.path.join(home, "config.json")
    if not os.path.exists(default_cfg):
        file = open(default_cfg, "w")
        file.write("{}")
        file.close()
    return default_cfg


@task
@serial
def who():
    assert(env.remote_interrupt)
    with settings(
        parallel=False,
        forward_agent=True,
        key_filename=FABRIC_KEY_FILENAME,
        user=FABRIC_USER,
        sudo_user=FABRIC_USER,
        remote_interrupt=True,
        keepalive=60,
        warn_only=True
    ):
        run("w", pty=True)  # prints 'mysql'


# def convert_unicode_to_str(data, encoding='utf-8'):

#     # ==============================================
#     # http://stackoverflow.com/a/1254499/42171
#     # ==============================================
#     if isinstance(data, basestring):
#         return data.encode(encoding) if isinstance(data, unicode) else \
#             data
#     elif isinstance(data, collections.Mapping):
#         return dict(map(convert_unicode_to_str, data.iteritems()))
#     elif isinstance(data, collections.Iterable):
#         return type(data)(map(convert_unicode_to_str, data))
#     else:
#         return data


# def policy_file_name(head_dir_path, tier):
#     policy_fname_json = "{}-policy.json".format(s3_buckets[tier])
#     return "{}/roles/awselb/static/{}".format(head_dir_path, policy_fname_json)


# def verify_policy_file_exists(tier):
#     # NOTE: To get the full path to the directory a Python file is contained in
#     absolute_dir_path = os.path.dirname(os.path.realpath(__file__))
#     head_dir_path, tail_dir_path = os.path.split(absolute_dir_path)
#     if not os.path.isfile(policy_file_name(head_dir_path, tier)):
#         print("File does not exist. ")
#         print("PATH: {}".format(policy_file_name(head_dir_path, tier)))
#         sys.exit(1)
#     return (head_dir_path, policy_file_name(head_dir_path, tier))


# def append_arn(data, toAdd):

#     pp.pprint(data)

#     if 'Statement' not in data:
#         raise ValueError("No target in given Statement")

#     for dest in data['Statement']:
#         if 'Resource' not in dest:
#             print('Naw')
#             continue
#         targetId = dest['Resource']
#         if toAdd not in dest['Resource']:
#             print('FOUND EVERYTHING EXCEPT FOR var=toAdd')
#             # toAdd_encoded = toAdd.encode(encoding='utf-8')
#             # dest['Resource'].append(toAdd_encoded)
#             dest['Resource'].append(toAdd)

#     print("Now that we've appended it, lets print again: ")
#     pp.pprint(data)

#     return data


# def change_policy_file_to_empty(path_to_policy_file):
#     with open(path_to_policy_file, mode='w') as f:
#         json.dump([], f)


# def read_policy_into_memory(path_to_policy_file):
#     with open(path_to_policy_file, mode='r') as data_file:
#         data = json.load(data_file)

#     pp.pprint(data)
#     return data


# def write_new_policy_to_disk(path_to_policy_file, data_after_append):
#     jsondata = simplejson.dumps(
#         data_after_append, indent=4, skipkeys=True, sort_keys=True)
#     fd = open(path_to_policy_file, mode='w')
#     fd.write(jsondata)
#     fd.close()

if __name__ == '__main__':

    valid_commands = ['restart', 'terminate']
