#!/usr/bin/python3
import asyncio

from pyback.api import app
from pyback.orders import response_handler


async def run():
    app.run()


async def main():
    await asyncio.gather(run(), response_handler())

if __name__ == "__main__":
    asyncio.run(main())
