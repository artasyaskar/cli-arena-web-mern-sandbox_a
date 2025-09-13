#!/bin/bash

# 1. Install dependencies
npm install next-seo

# 2. Create next-seo configuration
cat > next-seo.config.js << 'EOF'
export default {
  title: 'My Next.js App',
  description: 'This is a sample Next.js application with SEO setup.',
  canonical: 'https://example.com',
  openGraph: {
    type: 'website',
    locale: 'en_US',
    url: 'https://example.com',
    siteName: 'My Next.js App',
    title: 'My Next.js App',
    description: 'This is a sample Next.js application with SEO setup.',
    images: [
      {
        url: 'https://example.com/og-image.jpg',
        width: 1200,
        height: 630,
        alt: 'My Next.js App',
      },
    ],
  },
  twitter: {
    handle: '@example',
    site: '@example',
    cardType: 'summary_large_image',
  },
  additionalMetaTags: [
    {
      name: 'viewport',
      content: 'width=device-width, initial-scale=1',
    },
    {
      name: 'theme-color',
      content: '#000000',
    },
  ],
  additionalLinkTags: [
    {
      rel: 'icon',
      href: '/favicon.ico',
    },
    {
      rel: 'apple-touch-icon',
      href: '/apple-touch-icon.png',
      sizes: '180x180',
    },
  ],
}
EOF

# 3. Update _app.tsx
cat > src/pages/_app.tsx << 'EOF'
import type { AppProps } from 'next/app'
import { DefaultSeo } from 'next-seo'
import SEO from '../next-seo.config'

export default function App({ Component, pageProps }: AppProps) {
  return (
    <>
      <DefaultSeo {...SEO} />
      <Component {...pageProps} />
    </>
  )
}
EOF

# 4. Create index page with SEO overrides
cat > src/pages/index.tsx << 'EOF'
import { NextSeo } from 'next-seo'

export default function Home() {
  return (
    <>
      <NextSeo
        title="Home - My Next.js App"
        description="Welcome to our Next.js application with SEO optimization. This page demonstrates how to use next-seo for better search engine visibility."
        openGraph={{
          title: 'Home - My Next.js App',
          description: 'Welcome to our Next.js application with SEO optimization.',
          url: 'https://example.com',
          siteName: 'My Next.js App',
          images: [
            {
              url: 'https://example.com/home-og-image.jpg',
              width: 1200,
              height: 630,
              alt: 'Home page of My Next.js App',
            },
          ],
        }}
        additionalMetaTags={[
          {
            name: 'keywords',
            content: 'Next.js, React, SEO, next-seo, web development',
          },
        ]}
      />
      
      <div style={{ padding: '20px', fontFamily: 'Arial, sans-serif' }}>
        <h1>Welcome to My Next.js App</h1>
        <p>This is a sample Next.js application with SEO setup using next-seo.</p>
        
        <h2>SEO Features Implemented:</h2>
        <ul>
          <li>✅ Default SEO configuration</li>
          <li>✅ Open Graph meta tags</li>
          <li>✅ Twitter Card meta tags</li>
          <li>✅ Page-specific SEO overrides</li>
          <li>✅ Meta viewport and theme-color</li>
          <li>✅ Favicon and apple-touch-icon</li>
        </ul>
      </div>
    </>
  )
}
EOF

# 5. Create about page with different SEO
cat > src/pages/about.tsx << 'EOF'
import { NextSeo } from 'next-seo'

export default function About() {
  return (
    <>
      <NextSeo
        title="About Us - My Next.js App"
        description="Learn more about our company and what we do. We specialize in Next.js development and SEO optimization."
        openGraph={{
          title: 'About Us - My Next.js App',
          description: 'Learn more about our company and what we do.',
          url: 'https://example.com/about',
          siteName: 'My Next.js App',
        }}
        additionalMetaTags={[
          {
            name: 'keywords',
            content: 'about, company, team, Next.js, development',
          },
        ]}
      />
      
      <div style={{ padding: '20px', fontFamily: 'Arial, sans-serif' }}>
        <h1>About Us</h1>
        <p>This is the about page with custom SEO configuration.</p>
      </div>
    </>
  )
}
EOF

# 6. Create contact page with different SEO
cat > src/pages/contact.tsx << 'EOF'
import { NextSeo } from 'next-seo'

export default function Contact() {
  return (
    <>
      <NextSeo
        title="Contact Us - My Next.js App"
        description="Get in touch with us. We would love to hear from you and answer any questions you may have."
        openGraph={{
          title: 'Contact Us - My Next.js App',
          description: 'Get in touch with us.',
          url: 'https://example.com/contact',
          siteName: 'My Next.js App',
        }}
        additionalMetaTags={[
          {
            name: 'keywords',
            content: 'contact, get in touch, support, help',
          },
        ]}
      />
      
      <div style={{ padding: '20px', fontFamily: 'Arial, sans-serif' }}>
        <h1>Contact Us</h1>
        <p>This is the contact page with custom SEO configuration.</p>
      </div>
    </>
  )
}
EOF

# 7. Create SEO demo script
mkdir -p scripts
cat > scripts/seo-demo.js << 'EOF'
const fs = require('fs')

console.log('SEO Configuration Check')
console.log('======================')

// Check if next-seo.config.js exists
if (fs.existsSync('next-seo.config.js')) {
  console.log('✅ next-seo.config.js exists')
} else {
  console.log('❌ next-seo.config.js missing')
}

// Check if _app.tsx has DefaultSeo
if (fs.existsSync('src/pages/_app.tsx')) {
  const appContent = fs.readFileSync('src/pages/_app.tsx', 'utf8')
  if (appContent.includes('DefaultSeo')) {
    console.log('✅ _app.tsx includes DefaultSeo')
  } else {
    console.log('❌ _app.tsx missing DefaultSeo')
  }
} else {
  console.log('❌ _app.tsx missing')
}

// Check if index.tsx has NextSeo
if (fs.existsSync('src/pages/index.tsx')) {
  const indexContent = fs.readFileSync('src/pages/index.tsx', 'utf8')
  if (indexContent.includes('NextSeo')) {
    console.log('✅ index.tsx includes NextSeo')
  } else {
    console.log('❌ index.tsx missing NextSeo')
  }
} else {
  console.log('❌ index.tsx missing')
}

console.log('\nSEO setup verification complete!')
EOF
