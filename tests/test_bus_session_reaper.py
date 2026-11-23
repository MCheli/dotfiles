"""Tests for bin/bus-session-reaper with a faked `claude agents --json` and fake task files.

Run:  python3 -m unittest tests/test_bus_session_reaper.py
"""

import importlib.machinery
import importlib.util
import io
import json
import os
import subprocess
import tempfile
import unittest
from pathlib import Path

SCRIPT = Path(__file__).resolve().parent.parent / "bin" / "bus-session-reaper"


def load_module():
    loader = importlib.machinery.SourceFileLoader("bus_session_reaper", str(SCRIPT))
    spec = importlib.util.spec_from_loader(loader.name, loader)
    mod = importlib.util.module_from_spec(spec)
    loader.exec_module(mod)
    return mod


reaper = load_module()

HOUR = 3600
NOW = 1_800_000_000.0  # fixed "now" for every test


class ReaperHarness(unittest.TestCase):
    """A temp home with one bus registry, a jobs dir, a keep file and a log."""

    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        root = Path(self.tmp.name)
        self.bus_home = root / "session-bus-remote"
        (self.bus_home / "tasks").mkdir(parents=True)
        self.jobs_dir = root / "claude-jobs"
        self.jobs_dir.mkdir()
        self.keep_file = root / "config" / "keep.txt"
        self.log_file = root / "logs" / "reaper.log"
        self.cfg = reaper.Config(
            bus_homes=[self.bus_home], jobs_dir=self.jobs_dir, keep_file=self.keep_file,
            log_file=self.log_file, claude_bin="/nonexistent/claude",
        )
        self.agents = []
        self.stopped = []

    def tearDown(self):
        self.tmp.cleanup()

    # ── builders ──────────────────────────────────────────────────────────

    def add_task(self, task_id, name, bg_id, *, result_age=2 * HOUR, activity_age=2 * HOUR,
                 status="idle", state="done", live=True, kind="background", session_id=None,
                 in_flight=0, with_result=True):
        session_id = session_id or f"{bg_id}-0000-0000-0000-000000000000"
        result = self.bus_home / "tasks" / f"{task_id}.result.md"
        with (self.bus_home / "registry.jsonl").open("a") as fh:
            fh.write(json.dumps({
                "event": "spawn", "task_id": task_id, "name": name, "bg_id": bg_id,
                "session_id": session_id, "result": str(result),
            }) + "\n")
        if with_result:
            result.write_text(f"STATUS: done — {name}\n")
            self._touch(result, NOW - result_age)
        job_dir = self.jobs_dir / bg_id
        job_dir.mkdir()
        transcript = job_dir / "transcript.jsonl"
        transcript.write_text("{}\n")
        self._touch(transcript, NOW - activity_age)
        timeline = job_dir / "timeline.jsonl"
        timeline.write_text("{}\n")
        self._touch(timeline, NOW - activity_age)
        state_json = job_dir / "state.json"
        state_json.write_text(json.dumps({
            "state": state, "tempo": status, "inFlight": {"tasks": in_flight, "queued": 0},
            "linkScanPath": str(transcript), "updatedAt": _iso(NOW - activity_age),
            "lastTerminalAt": _iso(NOW - activity_age),
        }))
        self._touch(state_json, NOW - activity_age)
        job = {"id": bg_id, "cwd": "/tmp/repo", "kind": kind, "sessionId": session_id, "name": name,
               "state": state}
        if live:
            job["pid"] = 4242
            job["status"] = status
        self.agents.append(job)

    def add_own_session(self, bg_id, name, status="idle", state="done"):
        """A background job Mark started himself: in `claude agents`, not in any bus registry."""
        self.agents.append({"id": bg_id, "pid": 99, "kind": "background", "name": name,
                            "status": status, "state": state, "sessionId": f"{bg_id}-own"})

    @staticmethod
    def _touch(path, ts):
        os.utime(path, (ts, ts))

    # ── running ───────────────────────────────────────────────────────────

    def run_reaper(self, dry_run=False):
        self.cfg.dry_run = dry_run
        self.cfg.verbose = True
        out = io.StringIO()

        def fake_stop(cfg, short_id):
            self.stopped.append(short_id)
            return subprocess.CompletedProcess(["claude", "stop", short_id], 0, "", "")

        count = reaper.reap(self.cfg, agents_provider=lambda cfg: list(self.agents),
                            stopper=fake_stop, now=NOW, out=out)
        return count, out.getvalue()

    def log_text(self):
        return self.log_file.read_text() if self.log_file.exists() else ""


def _iso(ts):
    from datetime import datetime, timezone
    return datetime.fromtimestamp(ts, tz=timezone.utc).isoformat().replace("+00:00", "Z")


class TestDecisions(ReaperHarness):

    def test_idle_and_old_is_stopped(self):
        self.add_task("20261123-0905-2740", "ht-edge-backfill-check", "f93e19a7")
        count, out = self.run_reaper()
        self.assertEqual(count, 1)
        self.assertEqual(self.stopped, ["f93e19a7"])
        self.assertIn("stopped task=20261123-0905-2740 name=ht-edge-backfill-check short=f93e19a7", out)
        log = self.log_text()
        self.assertIn("STOP task=20261123-0905-2740 name=ht-edge-backfill-check short=f93e19a7", log)
        self.assertRegex(log, r"^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}[+-]\d{2}:\d{2} STOP")

    def test_working_job_is_skipped(self):
        self.add_task("20261123-1000-aaaa", "busy-one", "aaaa1111", status="busy", state="working")
        count, out = self.run_reaper()
        self.assertEqual(count, 0)
        self.assertEqual(self.stopped, [])
        self.assertIn("skip  task=20261123-1000-aaaa name=busy-one short=aaaa1111: status is 'busy'", out)

    def test_blocked_or_waiting_job_is_skipped(self):
        self.add_task("20261123-1000-bbbb", "needs-mark", "bbbb2222", status="idle", state="blocked")
        count, out = self.run_reaper()
        self.assertEqual(count, 0)
        self.assertIn("state is 'blocked', not done", out)

    def test_recent_result_is_skipped(self):
        self.add_task("20261123-1100-cccc", "fresh", "cccc3333", result_age=10 * 60, activity_age=10 * 60)
        count, out = self.run_reaper()
        self.assertEqual(count, 0)
        self.assertIn("result written 10 min ago", out)

    def test_old_result_but_recent_activity_is_skipped(self):
        self.add_task("20261123-1100-dddd", "poked", "dddd4444", result_age=3 * HOUR, activity_age=5 * 60)
        count, out = self.run_reaper()
        self.assertEqual(count, 0)
        self.assertIn("active 5 min ago", out)

    def test_keep_list_name_is_skipped(self):
        self.keep_file.parent.mkdir(parents=True)
        self.keep_file.write_text("# keep these\nai-context-obsidian-r630\n\n")
        self.add_task("20261123-0828-af20", "ai-context-obsidian-r630", "83379793")
        self.add_task("20261123-0905-2740", "ht-edge-backfill-check", "f93e19a7")
        count, out = self.run_reaper()
        self.assertEqual(count, 1)
        self.assertEqual(self.stopped, ["f93e19a7"])
        self.assertIn("name=ai-context-obsidian-r630 short=83379793: listed in keep.txt", out)

    def test_non_bus_job_is_never_touched(self):
        self.add_own_session("0wn11111", "marks-own-idle-session")
        self.add_own_session("0wn22222", "marks-own-busy-session", status="busy", state="working")
        count, out = self.run_reaper()
        self.assertEqual(count, 0)
        self.assertEqual(self.stopped, [])
        self.assertNotIn("marks-own", out)
        self.assertIn("stopped 0 of 0 live bus job(s)", out)

    def test_task_without_result_is_skipped(self):
        self.add_task("20261123-1130-eeee", "still-going", "eeee5555", with_result=False)
        count, out = self.run_reaper()
        self.assertEqual(count, 0)
        self.assertIn("no result file yet", out)

    def test_not_live_job_is_ignored(self):
        self.add_task("20261122-2011-7807", "ark-port-check", "b0aa205e", live=False)
        count, out = self.run_reaper()
        self.assertEqual(count, 0)
        self.assertIn("stopped 0 of 1 live bus job(s)", out)  # counted, but skipped as not live
        self.assertIn("not live (no pid)", out)

    def test_in_flight_work_is_skipped(self):
        self.add_task("20261123-1130-ffff", "subagent-running", "ffff6666", in_flight=1)
        count, out = self.run_reaper()
        self.assertEqual(count, 0)
        self.assertIn("work still in flight", out)

    def test_session_id_mismatch_is_skipped(self):
        self.add_task("20261123-1130-9999", "reused-id", "99998888")
        self.agents[-1]["sessionId"] = "someone-else"
        count, out = self.run_reaper()
        self.assertEqual(count, 0)
        self.assertIn("session id differs", out)

    def test_dry_run_stops_nothing_but_reports(self):
        self.add_task("20261123-0905-2740", "ht-edge-backfill-check", "f93e19a7")
        count, out = self.run_reaper(dry_run=True)
        self.assertEqual(count, 1)
        self.assertEqual(self.stopped, [])
        self.assertIn("WOULD STOP task=20261123-0905-2740 name=ht-edge-backfill-check short=f93e19a7", out)
        self.assertIn("DRY-RUN would stop", self.log_text())

    def test_failed_stop_is_logged_not_counted(self):
        self.add_task("20261123-0905-2740", "ht-edge-backfill-check", "f93e19a7")
        self.cfg.verbose = True
        out = io.StringIO()

        def failing_stop(cfg, short_id):
            return subprocess.CompletedProcess(["claude", "stop", short_id], 1, "", "no such session")

        count = reaper.reap(self.cfg, agents_provider=lambda cfg: list(self.agents),
                            stopper=failing_stop, now=NOW, out=out)
        self.assertEqual(count, 0)
        self.assertIn("ERROR stop task=20261123-0905-2740", self.log_text())

    def test_agents_failure_is_logged(self):
        def broken(cfg):
            raise RuntimeError("daemon down")

        count = reaper.reap(self.cfg, agents_provider=broken, now=NOW, out=io.StringIO())
        self.assertEqual(count, 0)
        self.assertIn("ERROR claude agents --json failed: daemon down", self.log_text())


class TestKeepFile(unittest.TestCase):

    def test_parses_names_comments_and_blanks(self):
        with tempfile.TemporaryDirectory() as d:
            p = Path(d) / "keep.txt"
            p.write_text("# comment\nalpha\n\n  beta  # trailing\n")
            self.assertEqual(reaper.load_keep_names(p), {"alpha", "beta"})

    def test_missing_file_means_nothing_kept(self):
        self.assertEqual(reaper.load_keep_names(Path("/nonexistent/keep.txt")), set())


class TestRegistry(unittest.TestCase):

    def test_only_spawn_events_with_bg_id(self):
        with tempfile.TemporaryDirectory() as d:
            home = Path(d)
            (home / "registry.jsonl").write_text("\n".join([
                json.dumps({"event": "spawn", "task_id": "t1", "name": "a", "bg_id": "aaaa0001"}),
                json.dumps({"event": "spawn", "task_id": "t2", "name": "b", "bg_id": None}),
                json.dumps({"event": "stop", "name": "a"}),
                "not json",
                json.dumps({"event": "spawn", "task_id": "t3", "name": "c", "bg_id": "cccc0003",
                            "result": str(home / "tasks" / "t3.result.md")}),
            ]) + "\n")
            tasks = reaper.load_registry_tasks(home)
            self.assertEqual(sorted(tasks), ["aaaa0001", "cccc0003"])
            self.assertEqual(tasks["aaaa0001"].result, home / "tasks" / "t1.result.md")
            self.assertEqual(tasks["cccc0003"].name, "c")


if __name__ == "__main__":
    unittest.main()
