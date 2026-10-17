#!/usr/bin/env python3
import sys
import os
import json
from datetime import datetime, timezone

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
if hasattr(sys.stdin, "reconfigure"):
    sys.stdin.reconfigure(encoding="utf-8", errors="replace")

def get_git_branch(start_path):
    if not start_path:
        return "none"
    curr = os.path.abspath(start_path)
    while True:
        git_entry = os.path.join(curr, ".git")
        if os.path.exists(git_entry):
            try:
                if os.path.isfile(git_entry):
                    with open(git_entry, "r", encoding="utf-8") as f:
                        line = f.read().strip()
                    if line.startswith("gitdir:"):
                        target = line[7:].strip()
                        git_entry = target if os.path.isabs(target) else os.path.join(curr, target)
                head_file = os.path.join(git_entry, "HEAD")
                if os.path.isfile(head_file):
                    with open(head_file, "r", encoding="utf-8") as f:
                        head = f.read().strip()
                    if head.startswith("ref: refs/heads/"):
                        return head[16:]
                    return head[:7] if head else "none"
            except Exception:
                pass
            break
        parent = os.path.dirname(curr)
        if parent == curr:
            break
        curr = parent
    return "none"

def get_quota_pct(bucket):
    if not bucket or not isinstance(bucket, dict):
        return "100%"
    rem = bucket.get("remaining_fraction")
    if rem is not None:
        try:
            return f"{round(float(rem) * 100.0)}%"
        except Exception:
            pass
    for k in ["remaining_percentage", "remaining_percent", "percent"]:
        val = bucket.get(k)
        if val is not None:
            try:
                return f"{round(float(val))}%"
            except Exception:
                pass
    return "100%"

def format_reset_duration(bucket):
    if not bucket or not isinstance(bucket, dict):
        return "0h 0m"
    secs = bucket.get("reset_in_seconds")
    if secs is None:
        reset_time_str = bucket.get("reset_time")
        if reset_time_str:
            try:
                t = datetime.fromisoformat(reset_time_str.replace("Z", "+00:00"))
                secs = int((t - datetime.now(timezone.utc)).total_seconds())
            except Exception:
                pass
    if secs is not None:
        try:
            secs = max(0, int(secs))
            h = secs // 3600
            m = (secs % 3600) // 60
            return f"{h}h {m}m"
        except Exception:
            pass
    return "0h 0m"

def main():
    raw_input = ""
    try:
        raw_input = sys.stdin.read()
    except Exception:
        pass

    data = {}
    if raw_input.strip():
        try:
            data = json.loads(raw_input)
            if os.environ.get("AGY_STATUSLINE_DEBUG"):
                log_path = os.path.expanduser("~/.gemini/antigravity-cli/statusline_last.json")
                with open(log_path, "w", encoding="utf-8") as f:
                    json.dump(data, f, indent=2)
        except Exception:
            pass

    # 1. Folder
    folder = ""
    folder_path = ""
    ws = data.get("workspace")
    if isinstance(ws, dict):
        folder_path = ws.get("current_dir") or ws.get("project_dir") or ""
        if folder_path:
            folder = os.path.basename(folder_path.rstrip("/\\"))
    if not folder:
        folder_path = data.get("cwd") or os.getcwd()
        folder = os.path.basename(folder_path.rstrip("/\\"))
    if not folder:
        folder = "unknown"

    # 2. Branch
    branch = ""
    vcs = data.get("vcs")
    if isinstance(vcs, dict):
        branch = vcs.get("branch") or ""
    if not branch:
        branch = get_git_branch(folder_path)

    # 3. Context filled %
    ctx_pct = "0%"
    ctx_w = data.get("context_window")
    if isinstance(ctx_w, dict):
        used_p = ctx_w.get("used_percentage")
        if used_p is not None:
            ctx_pct = f"{round(float(used_p))}%"
        else:
            used = ctx_w.get("total_input_tokens", 0) + ctx_w.get("total_output_tokens", 0)
            total = ctx_w.get("context_window_size", 0)
            if total > 0:
                ctx_pct = f"{round((used / total) * 100)}%"

    # 4. Usage based on selected model (Google vs Anthropic)
    model_data = data.get("model") if isinstance(data.get("model"), dict) else {}
    raw_model = model_data.get("display_name") or model_data.get("id") or "Gemini"
    model_identifier = f"{raw_model} {model_data.get('id', '')}".lower()
    is_anthropic = any(x in model_identifier for x in ["claude", "anthropic", "3p"])

    q = data.get("quota") if isinstance(data.get("quota"), dict) else {}
    if is_anthropic:
        wk_bucket = q.get("3p-weekly")
        fh_bucket = q.get("3p-5h")
    else:
        wk_bucket = q.get("gemini-weekly")
        fh_bucket = q.get("gemini-5h")

    wk_pct = get_quota_pct(wk_bucket)
    wk_time = format_reset_duration(wk_bucket)
    fh_pct = get_quota_pct(fh_bucket)
    fh_time = format_reset_duration(fh_bucket)

    usage_str = f"Week: {wk_pct} [{wk_time}] │ 5h: {fh_pct} [{fh_time}]"

    full_line = (
        f"🗀 {folder} · "
        f"⎇ {branch} · "
        f"Ctx: {ctx_pct} · "
        f"{usage_str}"
    )

    GREY = "\033[90m"
    RESET = "\033[0m"

    print(f"{GREY}{full_line}{RESET}", flush=True)

if __name__ == "__main__":
    main()
