# Common facilities I don't want to copy into every script all over again.
import os
import shlex
import subprocess
from itertools import accumulate
from math import log10
from pathlib import Path

# These environment variables are implicitly set by `../sh/initenv`,
# which is sourced on every system start/shell enter.
# To make them easier to access from Python, we just throw them into this module's scope.
envs_to_import = ["zero", "core", "state_share", "state_local"]
for name in envs_to_import:
    globals()[name] = Path(os.environ[name])


# https://en.wikipedia.org/wiki/Metric_prefix
SI_PREFIXES = list("BKMGTPEZYRQ")


def sh(*args) -> str:
    """
    Runs the given command *in a shell* and returns its stdout.
    stderr is emitted to the controlling terminal.
    """
    cmd = subprocess.run(args, text=True, stdout=subprocess.PIPE)
    return cmd.stdout


def friendly_size(
    size: int,
    units: list[str] = SI_PREFIXES,
) -> str:
    """
    Given a size in bytes,
    return a better comprehensible representation of it
    via the use of SI prefixes.
    Each increment is times 1024, NOT times 1000.
    """
    # divide size by 1024 until we've found a satisfying unit
    chosen = units[-1]
    for unit in units[:-1]:
        # are there less than 4 digits in front of the dot?
        if size == 0 or log10(size) < 3:
            chosen = unit
            break
        size /= 1024

    display = str(round(size, ndigits=2))
    return display + chosen
