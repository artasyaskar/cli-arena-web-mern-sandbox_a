import type { NextApiRequest, NextApiResponse } from 'next';

const messages = {
  en: {
    message: 'Hello from API',
    timestamp: 'Current timestamp',
    locale: 'Current locale',
  },
  es: {
    message: 'Hola desde la API',
    timestamp: 'Marca de tiempo actual',
    locale: 'Configuración regional actual',
  },
};

export default function handler(
  req: NextApiRequest,
  res: NextApiResponse,
): void {
  const { locale = 'en' } = req.query;
  const localeMessages =
    messages[locale as keyof typeof messages] || messages.en;

  res.status(200).json({
    message: localeMessages.message,
    timestamp: new Date().toISOString(),
    locale: locale,
    translatedTimestamp: localeMessages.timestamp,
    translatedLocale: localeMessages.locale,
  });
}
