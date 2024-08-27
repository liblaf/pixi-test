import concurrent.futures
import pathlib
import shutil
import subprocess as sp
import tempfile
from collections import defaultdict
from collections.abc import Callable
from concurrent.futures import Future, ThreadPoolExecutor


def test_pip(pkg: str) -> None:
    with tempfile.TemporaryDirectory() as _dtemp:
        dtemp: pathlib.Path = pathlib.Path(_dtemp)
        sp.run(
            ["python", "-m", "venv", dtemp / ".venv"],
            stdout=sp.DEVNULL,
            stderr=sp.DEVNULL,
            check=True,
        )
        sp.run(
            [dtemp / ".venv" / "bin" / "pip", "install", pkg],
            stdout=sp.DEVNULL,
            stderr=sp.DEVNULL,
            check=True,
        )


def test_pixi(pkg: str) -> None:
    with tempfile.TemporaryDirectory() as _dtemp:
        dtemp: pathlib.Path = pathlib.Path(_dtemp)
        shutil.copy("pyproject.toml", dtemp / "pyproject.toml")
        sp.run(
            ["pixi", "add", "--pypi", pkg],
            cwd=dtemp,
            stdout=sp.DEVNULL,
            stderr=sp.DEVNULL,
            check=True,
        )


def test_uv(pkg: str) -> None:
    with tempfile.TemporaryDirectory() as _dtemp:
        dtemp: pathlib.Path = pathlib.Path(_dtemp)
        sp.run(
            ["uv", "venv"], cwd=dtemp, stdout=sp.DEVNULL, stderr=sp.DEVNULL, check=True
        )
        sp.run(
            ["uv", "pip", "install", pkg],
            cwd=dtemp,
            stdout=sp.DEVNULL,
            stderr=sp.DEVNULL,
            check=True,
        )


class Records:
    _records: dict[str, dict[str, bool]]

    def __init__(self) -> None:
        self._records = defaultdict(dict)

    def test(self, fn: Callable[[str], None], name: str, pkg: str) -> None:
        result: bool
        try:
            fn(pkg)
        except Exception:
            result = False
        else:
            result = True
        finally:
            self._records[pkg][name] = result
            print(f"{name} {pkg} {'✅' if result else '❌'}")

    def summary(self) -> str:
        md: str = "| Package | pip | pixi | uv |\n"
        md += "| --- | --- | --- | --- |\n"
        for pkg in self._records:
            md += f"| {pkg} |"
            for tool in ["pip", "pixi", "uv"]:
                md += " ✅ |" if self._records[pkg][tool] else " ❌ |"
            md += "\n"
        return md


def main() -> None:
    pkg_file: pathlib.Path = pathlib.Path("pkg.txt")
    pkgs: list[str] = pkg_file.read_text().splitlines()
    records: Records = Records()
    with ThreadPoolExecutor() as executor:
        jobs: list[Future] = []
        for pkg in pkgs:
            jobs.append(executor.submit(records.test, test_pip, "pip", pkg))
            jobs.append(executor.submit(records.test, test_pixi, "pixi", pkg))
            jobs.append(executor.submit(records.test, test_uv, "uv", pkg))
        concurrent.futures.wait(jobs)
    pathlib.Path("results.md").write_text(records.summary())


if __name__ == "__main__":
    main()
