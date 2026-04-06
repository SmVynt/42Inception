import type React from "react"
import type { Metadata } from "next"
import "./globals.css"
import { Suspense } from "react"
import { siteContent } from "@/lib/site-content"

export const metadata: Metadata = {
  title: siteContent.metadata.title,
  description: siteContent.metadata.description,
  metadataBase: new URL(siteContent.person.siteUrl),
  icons: {
    icon: "/images/favicon.jpeg",
    shortcut: "/images/favicon.jpeg",
    apple: "/images/favicon.jpeg",
  },
  openGraph: {
    title: siteContent.metadata.title,
    description: siteContent.metadata.description,
    url: siteContent.person.siteUrl,
    siteName: siteContent.metadata.siteName,
    images: [
      {
        url: siteContent.person.imageUrl,
        width: 1280,
        height: 720,
        alt: siteContent.metadata.ogImageAlt,
        type: "image/png",
      },
    ],
    locale: siteContent.metadata.locale,
    type: "website",
  },
  twitter: {
    card: siteContent.metadata.twitterCard,
    title: siteContent.metadata.title,
    description: siteContent.metadata.description,
    images: [siteContent.person.imageUrl],
    creator: siteContent.person.handle,
  },
  appleWebApp: {
    capable: true,
    statusBarStyle: "black-translucent",
  }
}

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode
}>) {
  return (
    <html lang="en" className="dark" suppressHydrationWarning>
      <head>
        <link rel="icon" href="/images/favicon.jpeg" sizes="any" />

        <meta property="og:image" content={siteContent.person.imageUrl} />
        <meta property="og:image:url" content={siteContent.person.imageUrl} />
        <meta property="og:image:secure_url" content={siteContent.person.imageUrl} />
        <meta property="og:image:width" content="1280" />
        <meta property="og:image:height" content="720" />
        <meta property="og:image:alt" content={siteContent.metadata.ogImageAlt} />
        <meta property="og:image:type" content="image/png" />

        <meta name="twitter:image" content={siteContent.person.imageUrl} />
        <meta name="twitter:image:alt" content={siteContent.metadata.ogImageAlt} />
        <meta name="twitter:card" content="summary_large_image" />

        <meta property="og:type" content="website" />
        <meta property="og:url" content={siteContent.person.siteUrl} />
        <meta property="og:title" content={siteContent.metadata.title} />
        <meta property="og:description" content={siteContent.metadata.description} />
        <meta property="og:site_name" content={siteContent.metadata.siteName} />

        <meta name="apple-mobile-web-app-capable" content="yes" />
        <meta name="apple-mobile-web-app-status-bar-style" content="black-translucent" />
        <meta name="apple-mobile-web-app-title" content={siteContent.person.firstName} />
      </head>
      <body className="font-sans antialiased">
        <Suspense fallback={<div>Loading...</div>}>
          {children}
        </Suspense>
      </body>
    </html>
  )
}
