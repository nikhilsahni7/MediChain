import type React from "react"
import type { Metadata } from "next"
import { Inter } from "next/font/google"
import "./globals.css"
import { ThemeProvider } from "@/components/theme-provider"

const inter = Inter({ subsets: ["latin"] })

export const metadata: Metadata = {
  title: "MediChain - Connecting Hospitals, Sharing Medicines",
  description:
    "A platform that lets hospitals log their inventory, check what nearby hospitals have, and request critical drugs directly.",
}

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode
}>) {
  return (
    <html lang="en" suppressHydrationWarning>
      <body className={inter.className}>
        <ThemeProvider attribute="class" defaultTheme="system" enableSystem disableTransitionOnChange>
          <div className='main'>
            <div className='gradient' />
          </div>
          {children}
        </ThemeProvider>
      </body>
    </html>
  )
}

