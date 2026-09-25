"""Errors carry a stable code; the app translates the code into Indonesian or English.

The API never sends user-facing sentences for errors, so the backend does not need to
know the language of the interface (Bilingual ID-EN note, "Backend dan API").
"""

from __future__ import annotations

from typing import Any

from fastapi import FastAPI, Request
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse


class AppError(Exception):
    def __init__(self, code: str, status: int = 400, detail: Any = None) -> None:
        super().__init__(code)
        self.code = code
        self.status = status
        self.detail = detail


class NotFound(AppError):
    def __init__(self, what: str = "resource") -> None:
        super().__init__("not_found", 404, {"what": what})


def _body(code: str, detail: Any = None) -> dict:
    return {"error": {"code": code, "detail": detail}}


def install_error_handlers(app: FastAPI) -> None:
    @app.exception_handler(AppError)
    async def _app_error(_: Request, exc: AppError) -> JSONResponse:
        return JSONResponse(_body(exc.code, exc.detail), status_code=exc.status)

    @app.exception_handler(RequestValidationError)
    async def _validation(_: Request, exc: RequestValidationError) -> JSONResponse:
        fields = [".".join(str(p) for p in err.get("loc", ())[1:]) for err in exc.errors()]
        return JSONResponse(_body("validation_failed", {"fields": fields}), status_code=422)
