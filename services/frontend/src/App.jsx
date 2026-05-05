// services/frontend/src/App.jsx
import React, { Suspense, lazy } from 'react';
import { BrowserRouter as Router, Routes, Route } from 'react-router-dom';

// Lazy-loaded pages
const Home       = lazy(() => import('./pages/Home'));
const Products   = lazy(() => import('./pages/Products'));
const ProductDetail = lazy(() => import('./pages/ProductDetail'));
const Cart       = lazy(() => import('./pages/Cart'));
const Checkout   = lazy(() => import('./pages/Checkout'));
const Login      = lazy(() => import('./pages/Login'));
const Register   = lazy(() => import('./pages/Register'));
const Orders     = lazy(() => import('./pages/Orders'));
const NotFound   = lazy(() => import('./pages/NotFound'));

function LoadingSpinner() {
  return (
    <div style={{ display: 'flex', justifyContent: 'center', padding: '4rem' }}>
      <div>Loading...</div>
    </div>
  );
}

export default function App() {
  return (
    <Router>
      <Suspense fallback={<LoadingSpinner />}>
        <Routes>
          <Route path="/"                    element={<Home />} />
          <Route path="/products"            element={<Products />} />
          <Route path="/products/:id"        element={<ProductDetail />} />
          <Route path="/cart"                element={<Cart />} />
          <Route path="/checkout"            element={<Checkout />} />
          <Route path="/login"               element={<Login />} />
          <Route path="/register"            element={<Register />} />
          <Route path="/orders"              element={<Orders />} />
          <Route path="*"                    element={<NotFound />} />
        </Routes>
      </Suspense>
    </Router>
  );
}
