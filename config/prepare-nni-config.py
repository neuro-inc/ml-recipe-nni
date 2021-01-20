from typing import List

from neuro_sdk import get
from neuro_sdk import JobStatus
from neuro_cli.asyncio_utils import run as run_async
from jinja2 import Template


async def get_worker_hostnames() -> List[str]:
    result = []
    async with get() as client:
        async for job in client.jobs.list(statuses={JobStatus.RUNNING}, tags={"job:worker", "project:ml-recipe-nni"}):
            result.append(job.internal_hostname)
    return result


async def main() -> None:
    workers = await get_worker_hostnames()
    with open('./nni-config-template.yml') as template_file:
        template = Template(template_file.read())
    template.stream(workers=workers, worker_count=len(workers)).dump(
        './nni-config.yml')


run_async(main())