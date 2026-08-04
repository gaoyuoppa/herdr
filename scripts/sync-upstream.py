#!/usr/bin/env python3
"""Safely rebase the local herdr patch branch onto the official repository."""

from __future__ import annotations

import argparse
import datetime as dt
import os
import subprocess
import sys
from pathlib import Path


PROJECT_DIR = Path(__file__).resolve().parent.parent
DEFAULT_BRANCH = os.environ.get("HERDR_PATCH_BRANCH", "deploy/zh-with-perf")
DEFAULT_REMOTE = "upstream"
DEFAULT_REMOTE_URL = "https://github.com/herdrdev/herdr.git"


def run(*args: str, check: bool = True, capture: bool = False) -> subprocess.CompletedProcess[str]:
    command = ["git", *args]
    result = subprocess.run(
        command,
        cwd=PROJECT_DIR,
        check=False,
        text=True,
        stdout=subprocess.PIPE if capture else None,
        stderr=subprocess.PIPE if capture else None,
    )
    if check and result.returncode != 0:
        if capture:
            sys.stderr.write(result.stderr)
        raise subprocess.CalledProcessError(result.returncode, command)
    return result


def output(*args: str) -> str:
    return run(*args, capture=True).stdout.strip()


def require_clean_patch_branch(branch: str) -> None:
    current = output("branch", "--show-current")
    if current != branch:
        raise RuntimeError(f"当前分支是 {current or '(detached HEAD)'}，请切换到 {branch} 后重试")

    dirty = output("status", "--porcelain")
    if dirty:
        raise RuntimeError("工作区存在未提交改动；请先提交或手动 stash，脚本不会自动处理这些改动")


def ensure_remote(remote: str, remote_url: str) -> None:
    exists = run("remote", "get-url", remote, check=False, capture=True)
    if exists.returncode != 0:
        print(f"添加官方远程 {remote}: {remote_url}")
        run("remote", "add", remote, remote_url)


def validate() -> None:
    checks = (
        ("cargo", "fmt", "--check"),
        ("cargo", "check", "--locked"),
    )
    for command in checks:
        print(f"运行验证: {' '.join(command)}")
        result = subprocess.run(command, cwd=PROJECT_DIR, check=False)
        if result.returncode != 0:
            raise RuntimeError(f"验证失败: {' '.join(command)}")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="安全同步 herdr 官方 master 到本地补丁分支")
    parser.add_argument("--branch", default=DEFAULT_BRANCH, help=f"本地补丁分支（默认: {DEFAULT_BRANCH}）")
    parser.add_argument("--remote", default=DEFAULT_REMOTE, help=f"官方远程名（默认: {DEFAULT_REMOTE}）")
    parser.add_argument("--base", default="master", help="官方基线分支（默认: master）")
    parser.add_argument("--remote-url", default=DEFAULT_REMOTE_URL, help="远程不存在时使用的地址")
    parser.add_argument("--no-check", action="store_true", help="同步后跳过 cargo fmt/check")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    try:
        require_clean_patch_branch(args.branch)
        ensure_remote(args.remote, args.remote_url)

        print(f"拉取 {args.remote}（含标签并清理失效引用）...")
        run("fetch", args.remote, "--tags", "--prune")
        upstream_ref = f"{args.remote}/{args.base}"
        upstream_head = output("rev-parse", upstream_ref)
        local_head = output("rev-parse", "HEAD")

        already_contains = run(
            "merge-base", "--is-ancestor", upstream_ref, "HEAD", check=False
        ).returncode == 0
        if already_contains:
            print(f"已包含官方最新提交 {upstream_head[:12]}，无需 rebase。")
        else:
            timestamp = dt.datetime.now().strftime("%Y%m%d-%H%M%S")
            safe_branch = args.branch.replace("/", "-")
            backup = f"backup/{safe_branch}-pre-upstream-{timestamp}"
            run("branch", backup, local_head)
            print(f"已创建安全备份分支: {backup}")
            print(f"正在将 {args.branch} rebase 到 {upstream_ref} ({upstream_head[:12]})...")
            result = run("rebase", upstream_ref, check=False)
            if result.returncode != 0:
                print("\nrebase 遇到冲突，备份分支已保留。", file=sys.stderr)
                print("解决后执行 git rebase --continue；放弃则执行 git rebase --abort。", file=sys.stderr)
                return result.returncode

        # master is only an official baseline pointer; never mix local patches into it.
        run("branch", "-f", "master", upstream_ref)
        run("branch", "--set-upstream-to", upstream_ref, "master")
        run("branch", "--set-upstream-to", upstream_ref, args.branch)

        if not args.no_check:
            validate()

        print(f"同步完成: {output('rev-parse', '--short=12', 'HEAD')}")
        return 0
    except (RuntimeError, subprocess.CalledProcessError) as exc:
        print(f"错误: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
