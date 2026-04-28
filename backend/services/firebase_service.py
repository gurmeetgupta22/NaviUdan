import copy
import uuid
from collections import defaultdict

import firebase_admin
from firebase_admin import credentials, firestore, auth
from config import settings
import os

_db = None
_initialized = False

# In-memory store when Firestore is unavailable (local demo / no credentials).
_MEMORY: dict[str, dict[str, dict]] = defaultdict(dict)


def initialize_firebase():
    global _db, _initialized
    if _initialized:
        return _db

    cred_path = settings.firebase_credentials_path
    if os.path.exists(cred_path):
        cred = credentials.Certificate(cred_path)
        if not firebase_admin._apps:
            firebase_admin.initialize_app(cred)
        _db = firestore.client()
        _initialized = True
    else:
        print("⚠️  Firebase credentials not found. Using in-memory store for jobs/users.")
        _initialized = True
        _db = None
    return _db


def get_db():
    global _db
    if not _initialized:
        initialize_firebase()
    return _db


def get_auth():
    return auth


async def verify_firebase_token(id_token: str) -> dict:
    try:
        decoded = auth.verify_id_token(id_token)
        return decoded
    except Exception as e:
        raise ValueError(f"Invalid token: {str(e)}")


def _mem_apply_filters(rows: list, filters: list | None) -> list:
    if not filters:
        return rows
    out = rows
    for f in filters:
        field, op, val = f["field"], f["op"], f["value"]
        if op == "==":
            out = [r for r in out if r.get(field) == val]
    return out


def _memory_list(collection: str, filters: list | None) -> list:
    col = _MEMORY.get(collection, {})
    rows = []
    for doc_id, data in col.items():
        row = copy.deepcopy(data)
        row["id"] = doc_id
        rows.append(row)
    return _mem_apply_filters(rows, filters)


async def save_document(collection: str, doc_id: str, data: dict):
    db = get_db()
    if not db:
        existing = _MEMORY[collection].get(doc_id, {})
        merged = {**existing, **copy.deepcopy(dict(data))}
        merged["id"] = doc_id
        _MEMORY[collection][doc_id] = merged
        return
    doc_ref = db.collection(collection).document(doc_id)
    doc_ref.set(data, merge=True)


async def get_document(collection: str, doc_id: str) -> dict | None:
    db = get_db()
    if not db:
        d = _MEMORY.get(collection, {}).get(doc_id)
        if d is None:
            return None
        out = copy.deepcopy(d)
        out["id"] = doc_id
        return out
    doc_ref = db.collection(collection).document(doc_id)
    doc = doc_ref.get()
    if doc.exists:
        return doc.to_dict()
    return None


async def get_collection(collection: str, filters: list = None) -> list:
    db = get_db()
    if not db:
        return _memory_list(collection, filters)
    query = db.collection(collection)
    if filters:
        for f in filters:
            query = query.where(f["field"], f["op"], f["value"])
    docs = query.stream()
    result = []
    for doc in docs:
        d = doc.to_dict()
        d["id"] = doc.id
        result.append(d)
    return result


async def add_document(collection: str, data: dict) -> str:
    db = get_db()
    if not db:
        doc_id = f"m_{uuid.uuid4().hex[:18]}"
        _MEMORY[collection][doc_id] = copy.deepcopy(dict(data))
        return doc_id
    _, doc_ref = db.collection(collection).add(data)
    return doc_ref.id


async def update_document(collection: str, doc_id: str, data: dict):
    db = get_db()
    if not db:
        if doc_id not in _MEMORY.get(collection, {}):
            _MEMORY[collection][doc_id] = {}
        _MEMORY[collection][doc_id].update(copy.deepcopy(dict(data)))
        _MEMORY[collection][doc_id]["id"] = doc_id
        return
    db.collection(collection).document(doc_id).update(data)


async def delete_document(collection: str, doc_id: str):
    db = get_db()
    if not db:
        _MEMORY.get(collection, {}).pop(doc_id, None)
        return
    db.collection(collection).document(doc_id).delete()
