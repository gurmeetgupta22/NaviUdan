"""Filter jobs that are still within listing period."""

from __future__ import annotations

from datetime import datetime, timezone
from typing import Any, Dict, List, Optional


def _parse_expires_at(exp: Any) -> Optional[datetime]:
    """Normalize Firestore Timestamp, datetime, or ISO string to timezone-aware UTC."""
    if exp is None:
        return None

    if isinstance(exp, datetime):
        dt = exp
        if dt.tzinfo is None:
            return dt.replace(tzinfo=timezone.utc)
        return dt.astimezone(timezone.utc)

    # google.cloud.firestore_v1.types.Timestamp
    tn = type(exp).__name__
    if tn == "Timestamp" and hasattr(exp, "to_datetime"):
        return exp.to_datetime().replace(tzinfo=timezone.utc)
    if tn == "DatetimeWithNanoseconds":
        dt = exp
        if dt.tzinfo is None:
            return dt.replace(tzinfo=timezone.utc)
        return dt.astimezone(timezone.utc)

    raw = str(exp).strip()
    if not raw:
        return None
    raw = raw.replace("Z", "+00:00")
    try:
        dt = datetime.fromisoformat(raw)
    except ValueError:
        return None
    if dt.tzinfo is None:
        dt = dt.replace(tzinfo=timezone.utc)
    else:
        dt = dt.astimezone(timezone.utc)
    return dt


def job_is_visible(job: Dict[str, Any]) -> bool:
    if not job.get("is_active", True):
        return False
    exp = job.get("expires_at")
    if exp is None or exp == "":
        # No expiry set — treat as visible (legacy posts)
        return True
    dt = _parse_expires_at(exp)
    if dt is None:
        # Unparseable — keep visible rather than hiding valid jobs
        return True
    return datetime.now(timezone.utc) < dt


def filter_visible_jobs(jobs: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
    return [j for j in jobs if job_is_visible(j)]
