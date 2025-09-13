#!/bin/bash

# 1. Install dependencies
npm install next-i18next react-i18next i18next
npm install --save-dev @types/react-i18next

# 2. Create next-i18next configuration
cat > next-i18next.config.js << 'EOF'
module.exports = {
  i18n: {
    defaultLocale: 'en',
    locales: ['en', 'es'],
  },
  localePath: './src/locales',
}
EOF

# 3. Update next.config.js
cat > next.config.js << 'EOF'
const { i18n } = require('./next-i18next.config')

/** @type {import('next').NextConfig} */
const nextConfig = {
  experimental: {
    appDir: true,
  },
  output: 'standalone',
  i18n,
}

module.exports = nextConfig
EOF

# 4. Create locale directories and files
mkdir -p src/locales/en
mkdir -p src/locales/es

cat > src/locales/en/common.json << 'EOF'
{
  "welcome": "Welcome to our Next.js application",
  "description": "This is a sample page demonstrating internationalization",
  "language": "Language",
  "switchLanguage": "Switch Language",
  "features": "Features",
  "feature1": "Multi-language support",
  "feature2": "Easy language switching",
  "feature3": "Localized content",
  "apiMessage": "Hello from API"
}
EOF

cat > src/locales/es/common.json << 'EOF'
{
  "welcome": "Bienvenido a nuestra aplicación Next.js",
  "description": "Esta es una página de ejemplo que demuestra la internacionalización",
  "language": "Idioma",
  "switchLanguage": "Cambiar Idioma",
  "features": "Características",
  "feature1": "Soporte multi-idioma",
  "feature2": "Cambio fácil de idioma",
  "feature3": "Contenido localizado",
  "apiMessage": "Hola desde la API"
}
EOF

# 5. Update _app.tsx
cat > src/pages/_app.tsx << 'EOF'
import type { AppProps } from 'next/app'
import { appWithTranslation } from 'next-i18next'

function App({ Component, pageProps }: AppProps) {
  return <Component {...pageProps} />
}

export default appWithTranslation(App)
EOF

# 6. Create index page with language switcher
cat > src/pages/index.tsx << 'EOF'
import { GetStaticProps } from 'next'
import { useTranslation } from 'next-i18next'
import { serverSideTranslations } from 'next-i18next/serverSideTranslations'
import { useRouter } from 'next/router'

export default function Home() {
  const { t } = useTranslation('common')
  const router = useRouter()

  const changeLanguage = (locale: string) => {
    router.push(router.pathname, router.asPath, { locale })
  }

  return (
    <div style={{ padding: '20px', fontFamily: 'Arial, sans-serif' }}>
      <h1>{t('welcome')}</h1>
      <p>{t('description')}</p>
      
      <div style={{ margin: '20px 0' }}>
        <label>{t('language')}: </label>
        <select 
          value={router.locale} 
          onChange={(e) => changeLanguage(e.target.value)}
          style={{ padding: '5px', marginLeft: '10px' }}
        >
          <option value="en">English</option>
          <option value="es">Español</option>
        </select>
      </div>

      <h2>{t('features')}:</h2>
      <ul>
        <li>{t('feature1')}</li>
        <li>{t('feature2')}</li>
        <li>{t('feature3')}</li>
      </ul>

      <div style={{ marginTop: '30px', padding: '15px', backgroundColor: '#f5f5f5', borderRadius: '5px' }}>
        <h3>API Test:</h3>
        <p>Current locale: {router.locale}</p>
        <p>API endpoint: <a href={`/api/hello?locale=${router.locale}`}>/api/hello?locale={router.locale}</a></p>
      </div>
    </div>
  )
}

export const getStaticProps: GetStaticProps = async ({ locale }) => {
  return {
    props: {
      ...(await serverSideTranslations(locale || 'en', ['common'])),
    },
  }
}
EOF

# 7. Create localized API route
cat > src/pages/api/hello.ts << 'EOF'
import type { NextApiRequest, NextApiResponse } from 'next'

const messages = {
  en: {
    message: 'Hello from API',
    timestamp: 'Current timestamp',
    locale: 'Current locale'
  },
  es: {
    message: 'Hola desde la API',
    timestamp: 'Marca de tiempo actual',
    locale: 'Configuración regional actual'
  }
}

export default function handler(req: NextApiRequest, res: NextApiResponse) {
  const { locale = 'en' } = req.query
  const localeMessages = messages[locale as keyof typeof messages] || messages.en

  res.status(200).json({
    message: localeMessages.message,
    timestamp: new Date().toISOString(),
    locale: locale,
    translatedTimestamp: localeMessages.timestamp,
    translatedLocale: localeMessages.locale
  })
}
EOF
