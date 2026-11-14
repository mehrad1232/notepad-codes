from __future__ import annotations

import asyncio
import os
import secrets
import time
from contextlib import asynccontextmanager
from dataclasses import dataclass
from typing import Any
from urllib.parse import urlparse

from dotenv import load_dotenv
from fastapi import Depends, FastAPI, Header, HTTPException, Response
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field, HttpUrl
from playwright.async_api import Browser, BrowserContext, Page, async_playwright

load_dotenv()
TOKEN = os.getenv("NOVA_API_TOKEN", "")
TTL = max(60, int(os.getenv("NOVA_SESSION_TTL_SECONDS", "1800")))
MAX_SESSIONS = max(1, int(os.getenv("NOVA_MAX_SESSIONS", "3")))
QUALITY = min(90, max(25, int(os.getenv("NOVA_SCREENSHOT_QUALITY", "65"))))

@dataclass
class Session:
    context: BrowserContext
    page: Page
    touched: float

sessions: dict[str, Session] = {}
sessions_lock = asyncio.Lock()
browser: Browser | None = None
playwright_manager: Any = None

class CreateSession(BaseModel):
    url: HttpUrl = "https://web.bale.ai/"
    viewport_width: int = Field(390, ge=320, le=1440)
    viewport_height: int = Field(664, ge=320, le=1200)

class NavigateRequest(BaseModel):
    url: HttpUrl

class TapRequest(BaseModel):
    x: float = Field(..., ge=0, le=1)
    y: float = Field(..., ge=0, le=1)

class ScrollRequest(BaseModel):
    delta_x: int = Field(0, ge=-2000, le=2000)
    delta_y: int = Field(0, ge=-3000, le=3000)

class TypeRequest(BaseModel):
    text: str = Field(..., max_length=4000)

def require_token(authorization: str | None = Header(default=None)) -> None:
    if not TOKEN or len(TOKEN) < 24:
        raise HTTPException(503, "Cloud server is not configured: set NOVA_API_TOKEN to at least 24 characters")
    supplied = authorization.removeprefix("Bearer ").strip() if authorization else ""
    if not secrets.compare_digest(supplied, TOKEN):
        raise HTTPException(401, "Invalid NOVA token")

def validate_public_url(url: str) -> None:
    parsed = urlparse(url)
    host = (parsed.hostname or "").lower()
    if parsed.scheme not in {"http", "https"} or not host:
        raise HTTPException(400, "Only http and https URLs are allowed")
    if host in {"localhost", "127.0.0.1", "::1"} or host.endswith(".local"):
        raise HTTPException(400, "Local and loopback destinations are blocked")

async def cleanup_expired() -> None:
    now = time.monotonic()
    async with sessions_lock:
        expired = [sid for sid, s in sessions.items() if now - s.touched > TTL]
        for sid in expired:
            try:
                await sessions[sid].context.close()
            finally:
                sessions.pop(sid, None)

@asynccontextmanager
async def lifespan(app: FastAPI):
    global browser, playwright_manager
    playwright_manager = await async_playwright().start()
    browser = await playwright_manager.chromium.launch(headless=True, args=["--no-sandbox"])
    task = asyncio.create_task(expiry_loop())
    yield
    task.cancel()
    for session in list(sessions.values()):
        await session.context.close()
    sessions.clear()
    if browser:
        await browser.close()
    if playwright_manager:
        await playwright_manager.stop()

async def expiry_loop():
    while True:
        await asyncio.sleep(30)
        await cleanup_expired()

app = FastAPI(title="NOVA Cloud Engine", version="0.1.0", lifespan=lifespan)
app.add_middleware(CORSMiddleware, allow_origins=[], allow_credentials=False, allow_methods=["GET", "POST", "DELETE"], allow_headers=["Authorization", "Content-Type"])

async def get_session(session_id: str) -> Session:
    session = sessions.get(session_id)
    if not session:
        raise HTTPException(404, "Session not found or expired")
    session.touched = time.monotonic()
    return session

@app.get("/health")
async def health():
    return {"service": "NOVA Cloud Engine", "status": "ok", "version": "0.1.0"}

@app.post("/v1/sessions", dependencies=[Depends(require_token)])
async def create_session(request: CreateSession):
    validate_public_url(str(request.url))
    await cleanup_expired()
    async with sessions_lock:
        if len(sessions) >= MAX_SESSIONS:
            raise HTTPException(429, "Maximum concurrent sessions reached")
        context = await browser.new_context(viewport={"width": request.viewport_width, "height": request.viewport_height}, device_scale_factor=1, is_mobile=False)
        page = await context.new_page()
        sid = secrets.token_urlsafe(24)
        sessions[sid] = Session(context, page, time.monotonic())
    try:
        await page.goto(str(request.url), wait_until="domcontentloaded", timeout=45000)
    except Exception:
        # A page may still be usable after a network-idle or script timeout.
        pass
    return {"session_id": sid, "title": await page.title(), "url": page.url}

@app.get("/v1/sessions/{session_id}/screenshot", dependencies=[Depends(require_token)])
async def screenshot(session_id: str):
    session = await get_session(session_id)
    data = await session.page.screenshot(type="jpeg", quality=QUALITY, full_page=False)
    return Response(data, media_type="image/jpeg", headers={"Cache-Control": "no-store"})

@app.post("/v1/sessions/{session_id}/navigate", dependencies=[Depends(require_token)])
async def navigate(session_id: str, request: NavigateRequest):
    validate_public_url(str(request.url))
    session = await get_session(session_id)
    try:
        await session.page.goto(str(request.url), wait_until="domcontentloaded", timeout=45000)
    except Exception as exc:
        return {"ok": False, "error": str(exc)[:300], "url": session.page.url}
    return {"ok": True, "title": await session.page.title(), "url": session.page.url}

@app.post("/v1/sessions/{session_id}/tap", dependencies=[Depends(require_token)])
async def tap(session_id: str, request: TapRequest):
    session = await get_session(session_id)
    viewport = session.page.viewport_size or {"width": 390, "height": 664}
    await session.page.mouse.click(request.x * viewport["width"], request.y * viewport["height"])
    return {"ok": True}

@app.post("/v1/sessions/{session_id}/scroll", dependencies=[Depends(require_token)])
async def scroll(session_id: str, request: ScrollRequest):
    session = await get_session(session_id)
    await session.page.mouse.wheel(request.delta_x, request.delta_y)
    return {"ok": True}

@app.post("/v1/sessions/{session_id}/type", dependencies=[Depends(require_token)])
async def type_text(session_id: str, request: TypeRequest):
    session = await get_session(session_id)
    await session.page.keyboard.insert_text(request.text)
    return {"ok": True}

@app.post("/v1/sessions/{session_id}/key/{key}", dependencies=[Depends(require_token)])
async def press_key(session_id: str, key: str):
    allowed = {"Enter", "Tab", "Backspace", "Escape", "ArrowUp", "ArrowDown", "ArrowLeft", "ArrowRight", "Space"}
    if key not in allowed:
        raise HTTPException(400, "Unsupported key")
    session = await get_session(session_id)
    await session.page.keyboard.press(key)
    return {"ok": True}

@app.delete("/v1/sessions/{session_id}", dependencies=[Depends(require_token)])
async def close_session(session_id: str):
    session = sessions.pop(session_id, None)
    if session:
        await session.context.close()
    return {"ok": True}
