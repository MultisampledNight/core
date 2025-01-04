#!/usr/bin/env python3
import json
from configparser import ConfigParser

from dataclasses import dataclass, field
from itertools import starmap
from operator import itemgetter as get
from pathlib import Path
from multisn8 import sh

from collections.abc import Callable
from typing import TypeAlias, Self


ROOT = Path.home() / ".mozilla" / "firefox"
INDEX = ROOT / "profiles.ini"


class Config(dict):
    def to_userjs(self) -> str:
        ser = json.dumps
        calls = []
        for name, value in self.items():
            calls.append(f"user_pref({ser(name)}, {ser(value)})")
        return "\n".join(calls)


@dataclass
class Profile:
    # User-facing profile identifier.
    name: str

    # Extra custom configuration (to be) set in about:config.
    config: Config = field(default_factory=Config)

    # Actual on-disk folder name of the profile, or None if not created.
    path: str | None = None

    def __post_init__(self):
        # https://docs.python.org/3/library/dataclasses.html#post-init-processing
        if "/" in self.name:
            raise RuntimeError(
                f"`{name}` contains slashes which would break firefox. "
                "Don't use slashes in profile names."
            )

    @property
    def root(self):
        return ROOT / self.path

    @property
    def userjs(self):
        return self.root / "user.js"

    def create(self):
        """
        Creates the profile by telling firefox about it.
        This does not configure it and not set `path`.
        This is done by the manager, usually.
        """
        sh("firefox", "-createprofile", self.name)

    def configure(self):
        """
        Creates the profile by telling firefox about it.
        It has to exist already and `path` has to be set.
        """
        assert self.path is not None

        self.userjs.write_text(self.config.to_userjs())


@dataclass
class Manager:
    profiles: dict[str, Profile] = field(default_factory=dict)

    @classmethod
    def default(cls) -> Self:
        allow_login = lambda urls: {
            "privacy.clearOnShutdown_v2.cookies": False,
            "privacy.clearOnShutdown_v2.siteSettings": False,
        }
        homepage = lambda url: {
            "browser.startup.homepage": url,
        }
        only = lambda url: (allow_login([only]) | homepage(url))

        all = dict(
            fedi=only("https://mastodon.catgirl.cloud"),
            fedi2={},
            discord=only("https://discord.com"),
            git=allow_login(["https://github.com", "https://gitlab.com"]),
            spotify=only("https://open.spotify.com"),
            zulip={},
            # used by e.g. typst-preview or wled
            _app={},
        )
        all = zip(
            all.keys(),
            starmap(
                lambda name, config: Profile(name=name, config=Config(config)),
                all.items(),
            ),
        )
        return cls(profiles=dict(all))

    def load(self, index=INDEX):
        """
        Loads from disk from the index path
        and populates this manager with the current profiles,
        notably also setting `Profile.path`.
        Note that configurations are not replaced.
        """

        root = ConfigParser()
        root.read(index)

        for section in root.values():
            # OT: wonder how an entry api for python could look like
            if "name" not in section:
                continue

            name, path = get("name", "path")(section)
            if name in self.profiles:
                self.profiles[name].path = path
            else:
                # FIXME: also load existing cfg overrides
                self.profiles[name] = Profile(name=name, path=path)

    def write(self):
        """Writes to disk and applies configuration overrides."""
        self.forall(Profile.create)
        self.load()
        self.forall(Profile.configure)

    def forall(self, op: Callable[[Profile], None]):
        """Calls `op` over all profiles."""
        for profile in self.profiles.values():
            op(profile)


def main():
    Manager.default().write()


if __name__ == "__main__":
    main()
