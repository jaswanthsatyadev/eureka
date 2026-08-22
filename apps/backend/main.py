import uuid
from contextlib import asynccontextmanager
from fastapi import FastAPI, Request, Response
from fastapi.middleware.cors import CORSMiddleware
from fastapi.exceptions import RequestValidationError
from starlette.exceptions import HTTPException as StarletteHTTPException

from apps.backend.core.config import settings
from apps.backend.core.logging import setup_logging, get_logger, correlation_id_ctx
from apps.backend.core.exceptions import (
    AppException,
    app_exception_handler,
    http_exception_handler,
    validation_exception_handler,
    generic_exception_handler,
)

# Domain Routers
from apps.backend.domains.projects import router as projects_router
from apps.backend.domains.circuit import router as circuit_router
from apps.backend.domains.components import router as components_router
from apps.backend.domains.validation import router as validation_router
from apps.backend.domains.bom import router as bom_router
from apps.backend.domains.codegen import router as codegen_router
from apps.backend.domains.docs import router as docs_router
from apps.backend.domains.ai import router as ai_router
from apps.backend.domains.export import router as export_router
from apps.backend.domains.admin import router as admin_router


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup
    setup_logging(settings.LOG_LEVEL)
    logger = get_logger("main")
    logger.info(f"Starting Eureka Backend in {settings.ENVIRONMENT} mode")
    yield
    # Shutdown
    logger.info("Shutting down Eureka Backend")


app = FastAPI(
    title="Eureka - AI Electronics Project Builder API",
    description="Backend service powering natural-language to 2D circuit generation, BOM, firmware, and documentation.",
    version="0.1.0",
    docs_url="/docs",
    redoc_url="/redoc",
    openapi_url="/openapi.json",
    lifespan=lifespan,
)

# 1. CORS Middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origin_list,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# 2. Correlation ID Middleware
@app.middleware("http")
async def correlation_id_middleware(request: Request, call_next):
    corr_id = request.headers.get("X-Correlation-ID", str(uuid.uuid4()))
    token = correlation_id_ctx.set(corr_id)
    try:
        response: Response = await call_next(request)
        response.headers["X-Correlation-ID"] = corr_id
        return response
    finally:
        correlation_id_ctx.reset(token)


# 3. Exception Handlers (Convention #4)
app.add_exception_handler(AppException, app_exception_handler)
app.add_exception_handler(StarletteHTTPException, http_exception_handler)
app.add_exception_handler(RequestValidationError, validation_exception_handler)
app.add_exception_handler(Exception, generic_exception_handler)

# 4. Mount Domain Routers under /api/v1
API_V1_PREFIX = "/api/v1"
app.include_router(projects_router, prefix=API_V1_PREFIX)
app.include_router(circuit_router, prefix=API_V1_PREFIX)
app.include_router(components_router, prefix=API_V1_PREFIX)
app.include_router(validation_router, prefix=API_V1_PREFIX)
app.include_router(bom_router, prefix=API_V1_PREFIX)
app.include_router(codegen_router, prefix=API_V1_PREFIX)
app.include_router(docs_router, prefix=API_V1_PREFIX)
app.include_router(ai_router, prefix=API_V1_PREFIX)
app.include_router(export_router, prefix=API_V1_PREFIX)
app.include_router(admin_router, prefix=API_V1_PREFIX)


# 5. Health & Root Endpoints
@app.get("/health", tags=["system"])
async def health_check():
    """Service health check endpoint."""
    return {
        "status": "ok",
        "app": "Eureka AI Electronics Project Builder",
        "version": "0.1.0",
        "environment": settings.ENVIRONMENT,
    }


@app.get("/", tags=["system"])
async def root():
    return {
        "message": "Welcome to Eureka AI Electronics Project Builder API",
        "docs": "/docs",
        "health": "/health",
    }


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "apps.backend.main:app",
        host=settings.BACKEND_HOST,
        port=settings.BACKEND_PORT,
        reload=settings.ENVIRONMENT == "development",
    )
