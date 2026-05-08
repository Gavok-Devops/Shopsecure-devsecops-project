import React from 'react'

export default function App() {
  return (
    <div style={{ fontFamily: 'Arial, sans-serif', maxWidth: '800px', margin: '0 auto', padding: '2rem' }}>
      <h1 style={{ color: '#1B3A5C' }}>🛡️ ShopSecure</h1>
      <p style={{ color: '#374151' }}>Cloud-Native E-Commerce Platform</p>
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3,1fr)', gap: '1rem', marginTop: '2rem' }}>
        {['Products','Orders','Account'].map(function(item){
          return (
            <div key={item} style={{ background: '#F1F5F9', padding: '1.5rem', borderRadius: '8px', textAlign: 'center' }}>
              <h3 style={{ color: '#1D4ED8' }}>{item}</h3>
            </div>
          )
        })}
      </div>
      <p style={{ marginTop: '2rem', color: '#6B7280', fontSize: '0.875rem' }}>
        Running on AWS EKS · Deployed by ArgoCD · Monitored by Prometheus
      </p>
    </div>
  )
}
