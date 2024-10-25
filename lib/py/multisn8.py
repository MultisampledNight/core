# Common facilities I don't want to copy into every script all over again.
import os
from pathlib import Path

# These environment variables are implicitly set by `../sh/initenv`,
# which is sourced on every system start/shell enter.
# To make them easier to access from Python, we just throw them into this module's scope.
envs_to_import = ["zero", "core", "state_share", "state_local"]
for name in envs_to_import:
    globals()[name] = Path(os.environ[name])

