"""
ShopSecure — Product Service
FastAPI microservice for product catalog management
"""
from fastapi import FastAPI, HTTPException, Query
from fastapi.responses import JSONResponse
from prometheus_client import Counter, Histogram, generate_latest, CONTENT_TYPE_LATEST
from starlette.responses import Response
import time
import os
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(
    title="ShopSecure Product Service",
    version="1.0.0",
    docs_url="/docs" if os.getenv("ENV") != "production" else None,
)

# ── Prometheus metrics ───────────────────────────────────────────────────────
REQUEST_COUNT = Counter(
    "http_requests_total",
    "Total HTTP requests",
    ["method", "endpoint", "status"]
)
REQUEST_LATENCY = Histogram(
    "http_request_duration_seconds",
    "HTTP request latency",
    ["method", "endpoint"]
)

@app.middleware("http")
async def metrics_middleware(request, call_next):
    start = time.time()
    response = await call_next(request)
    duration = time.time() - start
    REQUEST_COUNT.labels(request.method, request.url.path, response.status_code).inc()
    REQUEST_LATENCY.labels(request.method, request.url.path).observe(duration)
    return response

# ── Health endpoints ─────────────────────────────────────────────────────────
@app.get("/health/live")
async def liveness():
    return {"status": "alive"}

@app.get("/health/ready")
async def readiness():
    # Add DB connectivity check here
    return {"status": "ready"}

@app.get("/metrics")
async def metrics():
    return Response(generate_latest(), media_type=CONTENT_TYPE_LATEST)

# ── Product endpoints ────────────────────────────────────────────────────────
@app.get("/api/v1/products")
async def list_products(
    q: str = Query(None, description="Search query"),
    page: int = Query(1, ge=1),
    limit: int = Query(20, ge=1, le=100),
    category: str = Query(None),
):
    """List products with optional search and filtering."""
    logger.info(f"Listing products: q={q}, page={page}, category={category}")
    # TODO: Implement DB query via SQLAlchemy
    return {
        "products": [],
        "total": 0,
        "page": page,
        "limit": limit,
    }

@app.get("/api/v1/products/{product_id}")
async def get_product(product_id: str):
    """Get a single product by ID."""
    # TODO: Implement DB lookup
    raise HTTPException(status_code=404, detail="Product not found")

@app.post("/api/v1/products")
async def create_product(product: dict):
    """Create a new product (admin only)."""
    # TODO: Validate with Pydantic model, write to DB
    return JSONResponse(status_code=201, content={"id": "new-id", **product})

@app.put("/api/v1/products/{product_id}")
async def update_product(product_id: str, product: dict):
    """Update a product (admin only)."""
    # TODO: Implement
    raise HTTPException(status_code=404, detail="Product not found")

@app.delete("/api/v1/products/{product_id}")
async def delete_product(product_id: str):
    """Soft-delete a product (admin only)."""
    # TODO: Implement
    raise HTTPException(status_code=404, detail="Product not found")
