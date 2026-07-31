"""Regression cover for M-3: the Dockerfile ran as root with no .dockerignore,
so `COPY . .` would bake a populated local .env (real secrets) into an image
layer if one existed at build time, and the running process had root inside
the container — unnecessary blast radius for a service that just needs to
listen on 8000 and talk to Postgres/Redis.

These are genuine `docker build`/`docker run` checks, not mocks — skipped
(not failed) if the Docker daemon isn't reachable in this environment, since
that's an environment gap, not a code regression.
"""

import shutil
import subprocess
import uuid

import pytest

BACKEND_ROOT = __import__("pathlib").Path(__file__).resolve().parent.parent
IMAGE_TAG = f"smartspend-backend-hardening-test-{uuid.uuid4().hex[:8]}"


def _docker_available() -> bool:
    if shutil.which("docker") is None:
        return False
    try:
        subprocess.run(["docker", "info"], capture_output=True, timeout=10, check=True)
        return True
    except Exception:
        return False


pytestmark = pytest.mark.skipif(not _docker_available(), reason="Docker daemon not reachable")


@pytest.fixture(scope="module")
def built_image():
    subprocess.run(
        ["docker", "build", "-t", IMAGE_TAG, "."],
        cwd=BACKEND_ROOT, check=True, capture_output=True, timeout=300,
    )
    yield IMAGE_TAG
    subprocess.run(["docker", "rmi", "-f", IMAGE_TAG], capture_output=True)


def _run_in_image(image: str, *cmd: str) -> str:
    result = subprocess.run(
        ["docker", "run", "--rm", image, *cmd],
        capture_output=True, text=True, timeout=30, check=True,
    )
    return result.stdout.strip()


def test_image_builds_successfully(built_image):
    assert built_image  # fixture already asserts check=True on the build


def test_container_runs_as_non_root_user(built_image):
    assert _run_in_image(built_image, "whoami") == "app"
    uid_output = _run_in_image(built_image, "id", "-u")
    assert uid_output != "0", "container process must not run as root (uid 0)"


def test_no_real_env_file_reaches_the_image_even_when_present_at_build_time(tmp_path):
    """The most important case: a developer with a populated local .env
    (real secrets) runs `docker build` — .dockerignore must keep it out."""
    env_path = BACKEND_ROOT / ".env"
    assert not env_path.exists(), "a real .env must not already exist in the repo during this test"

    tag = f"{IMAGE_TAG}-envcheck"
    secret_marker = f"test-secret-{uuid.uuid4().hex}"
    env_path.write_text(f"JWT_SECRET_KEY={secret_marker}\n")
    try:
        subprocess.run(
            ["docker", "build", "-t", tag, "."],
            cwd=BACKEND_ROOT, check=True, capture_output=True, timeout=300,
        )
        found_env_files = _run_in_image(
            tag, "sh", "-c", "find /app -iname '.env*' -not -name '.env.example'"
        )
        assert found_env_files == "", f"unexpected env file(s) in image: {found_env_files!r}"

        grep_result = subprocess.run(
            ["docker", "run", "--rm", tag, "sh", "-c", f"grep -rl {secret_marker} /app 2>/dev/null || true"],
            capture_output=True, text=True, timeout=30,
        )
        assert secret_marker not in grep_result.stdout, "the real secret leaked into the image"
    finally:
        env_path.unlink(missing_ok=True)
        subprocess.run(["docker", "rmi", "-f", tag], capture_output=True)


def test_tests_directory_is_excluded_from_the_image(built_image):
    result = subprocess.run(
        ["docker", "run", "--rm", built_image, "sh", "-c", "test -d /app/tests && echo present || echo absent"],
        capture_output=True, text=True, timeout=30, check=True,
    )
    assert result.stdout.strip() == "absent"


def test_app_still_imports_and_runs_correctly_as_non_root(built_image):
    output = _run_in_image(
        built_image, "python", "-c",
        "from app.main import create_application; import os; print(os.getuid())",
    )
    assert output == "1000"
