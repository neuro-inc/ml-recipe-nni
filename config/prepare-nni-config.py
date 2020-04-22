import asyncio
import socket
from pathlib import Path
from typing import List
import aiodns

from neuromation import api as neuro_api
from neuromation.api import JobStatus, DEFAULT_CONFIG_PATH
from neuromation.cli.asyncio_utils import run as run_async
from jinja2 import Template
from neuromation.cli.utils import steal_config_maybe


async def get_worker_hostnames() -> List[str]:
    steal_config_maybe(Path(DEFAULT_CONFIG_PATH))
    async with neuro_api.get() as client:
        jobs = await client.jobs.list(
            statuses={JobStatus.RUNNING},
            tags={"hypertrain:worker", "target:hypertrain"}
        )
        return [job.internal_hostname for job in jobs]


async def query(name: str, resolver: aiodns.DNSResolver) -> str:
    result = await resolver.gethostbyname(name, socket.AF_INET)
    return result.addresses[0]


async def main() -> None:
    resolver = aiodns.DNSResolver(loop=asyncio.get_event_loop())
    workers = await get_worker_hostnames()
    worker_ips = [await query(hostname, resolver) for hostname in workers]
    with open('./nni-config-template.yml') as template_file:
        template = Template(template_file.read())
    template.stream(worker_ips=worker_ips, worker_count=len(worker_ips)).dump(
        './nni-config.yml')


run_async(main())
