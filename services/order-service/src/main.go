// services/order-service/src/main.go
// ShopSecure — Order Service (Go / Gin)
package main

import (
	"net/http"
	"os"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promauto"
	"github.com/prometheus/client_golang/prometheus/promhttp"
)

// ── Prometheus metrics ────────────────────────────────────────────────────────
var (
	requestCount = promauto.NewCounterVec(prometheus.CounterOpts{
		Name: "http_requests_total",
		Help: "Total HTTP requests",
	}, []string{"method", "path", "status"})

	requestDuration = promauto.NewHistogramVec(prometheus.HistogramOpts{
		Name:    "http_request_duration_seconds",
		Help:    "HTTP request latency",
		Buckets: prometheus.DefBuckets,
	}, []string{"method", "path"})
)

func metricsMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		start := time.Now()
		c.Next()
		duration := time.Since(start).Seconds()
		status := http.StatusText(c.Writer.Status())
		requestCount.WithLabelValues(c.Request.Method, c.FullPath(), status).Inc()
		requestDuration.WithLabelValues(c.Request.Method, c.FullPath()).Observe(duration)
	}
}

// ── Order types ───────────────────────────────────────────────────────────────
type OrderItem struct {
	ProductID string  `json:"product_id" binding:"required"`
	Quantity  int     `json:"quantity"   binding:"required,min=1"`
	Price     float64 `json:"price"`
}

type Order struct {
	ID         string      `json:"id"`
	UserID     string      `json:"user_id"`
	Items      []OrderItem `json:"items"     binding:"required,dive"`
	Status     string      `json:"status"`
	TotalAmount float64    `json:"total_amount"`
	CreatedAt  time.Time   `json:"created_at"`
}

// ── Handlers ──────────────────────────────────────────────────────────────────
func listOrders(c *gin.Context) {
	userID := c.GetHeader("X-User-ID")
	if userID == "" {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "authentication required"})
		return
	}
	// TODO: fetch orders from DB filtered by userID
	c.JSON(http.StatusOK, gin.H{"orders": []Order{}, "total": 0})
}

func getOrder(c *gin.Context) {
	orderID := c.Param("id")
	// TODO: fetch from DB, verify ownership
	c.JSON(http.StatusNotFound, gin.H{"error": "order not found", "id": orderID})
}

func createOrder(c *gin.Context) {
	var order Order
	if err := c.ShouldBindJSON(&order); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	// TODO: validate stock, create order in DB, publish to SQS
	order.ID = "ord-placeholder"
	order.Status = "pending"
	order.CreatedAt = time.Now()
	c.JSON(http.StatusCreated, order)
}

func cancelOrder(c *gin.Context) {
	orderID := c.Param("id")
	// TODO: check order state machine allows cancellation
	c.JSON(http.StatusOK, gin.H{"id": orderID, "status": "cancelled"})
}

func main() {
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	if os.Getenv("ENV") == "production" {
		gin.SetMode(gin.ReleaseMode)
	}

	r := gin.New()
	r.Use(gin.Recovery())
	r.Use(metricsMiddleware())

	// Health
	r.GET("/health/live",  func(c *gin.Context) { c.JSON(200, gin.H{"status": "alive"}) })
	r.GET("/health/ready", func(c *gin.Context) { c.JSON(200, gin.H{"status": "ready"}) })
	r.GET("/metrics",      gin.WrapH(promhttp.Handler()))

	// Orders API
	v1 := r.Group("/api/v1")
	{
		v1.GET("/orders",        listOrders)
		v1.GET("/orders/:id",    getOrder)
		v1.POST("/orders",       createOrder)
		v1.DELETE("/orders/:id", cancelOrder)
	}

	r.Run(":" + port)
}
