import { Button } from "@/components/ui/button"
import { ThemeToggle } from "@/components/theme-toggle"
import { Badge } from "@/components/ui/badge"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs"
import { Pill, Stethoscope, Map, Building2, ShieldCheck, Camera, Zap } from "lucide-react"
import qr from '@/assets/qr.jpeg'

import { Space_Grotesk } from "next/font/google"
import Image from "next/image"

const space = Space_Grotesk({
  subsets: ["latin"],
  variable: "--font-space-grotesk",
})

export default function Home() {
  return (
    <div className={`flex min-h-screen flex-col ${space.className}`}>
      <header className="sticky top-0 z-50 w-full border-b bg-background/95 backdrop-blur supports-[backdrop-filter]:bg-background/60">
        <div className="container flex h-16 items-center justify-between">
          <div className="flex items-center gap-2">
            <Pill className="h-6 w-6 text-purple-500" />
            <span className="text-xl font-bold">MediChain</span>
          </div>
          <nav className="hidden md:flex items-center gap-6">
            <a href="#features" className="text-sm font-medium hover:underline underline-offset-4">
              Features
            </a>
            <a href="#how-it-works" className="text-sm font-medium hover:underline underline-offset-4">
              How It Works
            </a>
          </nav>
          <div className="flex items-center gap-4">
            <ThemeToggle />
            <Button asChild className="bg-purple-500 text-white hover:bg-purple-600">
              <a href="https://drive.google.com/drive/folders/15X4itFNZyRpd2yJrQuTXFbmyUse49CmH?usp=sharing">Download App</a>
            </Button>
          </div>
        </div>
      </header>

      <main className="flex-1">
        {/* Hero Section */}
        <section className="py-20 md:py-28">
          <div className="container flex flex-col items-center text-center">
            <Badge className="mb-4 border-purple-500" variant="outline">
              Beta Release
            </Badge>
            <h1 className="text-4xl md:text-6xl font-bold tracking-tight mb-6">
              Connecting Hospitals, <span className="text-purple-500">Saving Lives</span>
            </h1>
            <p className="text-lg md:text-xl text-muted-foreground max-w-[800px] mb-8">
              MediChain helps hospitals coordinate medicine shortages and surpluses in real-time, making critical drug
              sharing faster and more efficient.
            </p>
            <div className="flex flex-col sm:flex-row gap-4">
              <Button size="lg" asChild className="bg-purple-500 text-white hover:bg-purple-600">
                <a
                  href="https://drive.google.com/drive/folders/15X4itFNZyRpd2yJrQuTXFbmyUse49CmH?usp=sharing"
                  target="_blank"
                  rel="noopener noreferrer"
                >
                  Download Now
                </a>
              </Button>
            </div>
          </div>
        </section>

        {/* Features Section */}
        <section id="features" className="py-20 bg-muted/50">
          <div className="container">
            <div className="text-center mb-16">
              <h2 className="text-3xl md:text-4xl font-bold mb-4">Powerful Features</h2>
              <p className="text-lg text-muted-foreground max-w-[600px] mx-auto">
                MediChain connects hospitals with a suite of tools designed to make medicine sharing simple and
                efficient.
              </p>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8">
              <Card>
                <CardHeader>
                  <div className="h-10 w-10 rounded-full bg-purple-100 dark:bg-purple-900/30 flex items-center justify-center mb-2">
                    <Building2 className="h-5 w-5 text-purple-500" />
                  </div>
                  <CardTitle>Inventory Dashboard</CardTitle>
                </CardHeader>
                <CardContent>
                  <p className="text-muted-foreground">
                    Track your hospital's medicine inventory with a simple dashboard. Add, update, and monitor your
                    stock levels.
                  </p>
                </CardContent>
              </Card>

              <Card>
                <CardHeader>
                  <div className="h-10 w-10 rounded-full bg-purple-100 dark:bg-purple-900/30 flex items-center justify-center mb-2">
                    <Camera className="h-5 w-5 text-purple-500" />
                  </div>
                  <CardTitle>AI-Powered Detection</CardTitle>
                </CardHeader>
                <CardContent>
                  <p className="text-muted-foreground">
                    Take photos of medicines and let Gemini AI automatically detect drug names and quantities to save
                    time.
                  </p>
                </CardContent>
              </Card>

              <Card>
                <CardHeader>
                  <div className="h-10 w-10 rounded-full bg-purple-100 dark:bg-purple-900/30 flex items-center justify-center mb-2">
                    <Map className="h-5 w-5 text-purple-500" />
                  </div>
                  <CardTitle>Nearby Hospitals Map</CardTitle>
                </CardHeader>
                <CardContent>
                  <p className="text-muted-foreground">
                    View nearby hospitals on a map with their available medicines. Adjust search radius to find what you
                    need.
                  </p>
                </CardContent>
              </Card>

              <Card>
                <CardHeader>
                  <div className="h-10 w-10 rounded-full bg-purple-100 dark:bg-purple-900/30 flex items-center justify-center mb-2">
                    <Stethoscope className="h-5 w-5 text-purple-500" />
                  </div>
                  <CardTitle>Medicine Requests</CardTitle>
                </CardHeader>
                <CardContent>
                  <p className="text-muted-foreground">
                    Request medicines from other hospitals with a few taps. Approve or deny incoming requests easily.
                  </p>
                </CardContent>
              </Card>

              <Card>
                <CardHeader>
                  <div className="h-10 w-10 rounded-full bg-purple-100 dark:bg-purple-900/30 flex items-center justify-center mb-2">
                    <Zap className="h-5 w-5 text-purple-500" />
                  </div>
                  <CardTitle>Multiple Payment Options</CardTitle>
                </CardHeader>
                <CardContent>
                  <p className="text-muted-foreground">
                    Pay for medicines using Razorpay or Coinbase with integrated payment processing for quick
                    transactions.
                  </p>
                </CardContent>
              </Card>

              <Card>
                <CardHeader>
                  <div className="h-10 w-10 rounded-full bg-purple-100 dark:bg-purple-900/30 flex items-center justify-center mb-2">
                    <ShieldCheck className="h-5 w-5 text-purple-500" />
                  </div>
                  <CardTitle>Blockchain Audit Trail</CardTitle>
                </CardHeader>
                <CardContent>
                  <p className="text-muted-foreground">
                    Every transaction is recorded on the blockchain, providing a verifiable audit trail for compliance.
                  </p>
                </CardContent>
              </Card>
            </div>
          </div>
        </section>

        {/* How It Works Section */}
        <section id="how-it-works" className="py-20">
          <div className="container">
            <div className="text-center mb-16">
              <h2 className="text-3xl md:text-4xl font-bold mb-4">How MediChain Works</h2>
              <p className="text-lg text-muted-foreground max-w-[600px] mx-auto">
                Our platform simplifies the process of sharing medicines between hospitals.
              </p>
            </div>

            <Tabs defaultValue="inventory" className="max-w-4xl mx-auto">
              <TabsList className="grid w-full grid-cols-3">
                <TabsTrigger value="inventory">Inventory</TabsTrigger>
                <TabsTrigger value="discover">Discover</TabsTrigger>
                <TabsTrigger value="request">Request</TabsTrigger>
              </TabsList>
              <TabsContent value="inventory" className="mt-6">
                <div className="text-center">
                  <div className="flex flex-col items-center">
                    <h3 className="text-2xl font-bold mb-4">Manage Your Inventory</h3>
                    <ul className="space-y-4">
                      <li className="flex gap-3">
                        <div className="h-6 w-6 rounded-full bg-purple-100 dark:bg-purple-900/30 flex items-center justify-center flex-shrink-0 mt-0.5">
                          <span className="text-xs font-bold text-purple-500">1</span>
                        </div>
                        <p>Log in to your hospital dashboard to view current inventory</p>
                      </li>
                      <li className="flex gap-3">
                        <div className="h-6 w-6 rounded-full bg-purple-100 dark:bg-purple-900/30 flex items-center justify-center flex-shrink-0 mt-0.5">
                          <span className="text-xs font-bold text-purple-500">2</span>
                        </div>
                        <p>Take photos of medicines to automatically add them with AI detection</p>
                      </li>
                      <li className="flex gap-3">
                        <div className="h-6 w-6 rounded-full bg-purple-100 dark:bg-purple-900/30 flex items-center justify-center flex-shrink-0 mt-0.5">
                          <span className="text-xs font-bold text-purple-500">3</span>
                        </div>
                        <p>Review suggested market prices and confirm with a single click</p>
                      </li>
                    </ul>
                  </div>
                </div>
              </TabsContent>
              <TabsContent value="discover" className="mt-6">
                <div className="text-center">
                  <div className="flex flex-col items-center">
                    <h3 className="text-2xl font-bold mb-4">Find Nearby Medicines</h3>
                    <ul className="space-y-4">
                      <li className="flex gap-3 items-center">
                        <div className="h-6 w-6 rounded-full bg-purple-100 dark:bg-purple-900/30 flex items-center justify-center flex-shrink-0 mt-0.5">
                          <span className="text-xs font-bold text-purple-500">1</span>
                        </div>
                        <p>View the map of nearby hospitals with available medicines</p>
                      </li>
                      <li className="flex gap-3">
                        <div className="h-6 w-6 rounded-full bg-purple-100 dark:bg-purple-900/30 flex items-center justify-center flex-shrink-0 mt-0.5">
                          <span className="text-xs font-bold text-purple-500">2</span>
                        </div>
                        <p>Adjust the search radius to expand or narrow your search</p>
                      </li>
                      <li className="flex gap-3">
                        <div className="h-6 w-6 rounded-full bg-purple-100 dark:bg-purple-900/30 flex items-center justify-center flex-shrink-0 mt-0.5">
                          <span className="text-xs font-bold text-purple-500">3</span>
                        </div>
                        <p>Browse available medicines at each hospital in real-time</p>
                      </li>
                    </ul>
                  </div>
                </div>
              </TabsContent>
              <TabsContent value="request" className="mt-6">
                <div className="text-center">
                  <div className="flex flex-col items-center">
                    <h3 className="text-2xl font-bold mb-4">Request & Transfer</h3>
                    <ul className="space-y-4">
                      <li className="flex gap-3">
                        <div className="h-6 w-6 rounded-full bg-purple-100 dark:bg-purple-900/30 flex items-center justify-center flex-shrink-0 mt-0.5">
                          <span className="text-xs font-bold text-purple-500">1</span>
                        </div>
                        <p>Request medicines directly from hospitals that have them in stock</p>
                      </li>
                      <li className="flex gap-3">
                        <div className="h-6 w-6 rounded-full bg-purple-100 dark:bg-purple-900/30 flex items-center justify-center flex-shrink-0 mt-0.5">
                          <span className="text-xs font-bold text-purple-500">2</span>
                        </div>
                        <p>Receive approval notifications and confirm the transaction</p>
                      </li>
                      <li className="flex gap-3">
                        <div className="h-6 w-6 rounded-full bg-purple-100 dark:bg-purple-900/30 flex items-center justify-center flex-shrink-0 mt-0.5">
                          <span className="text-xs font-bold text-purple-500">3</span>
                        </div>
                        <p>Complete payment through Razorpay or Coinbase with blockchain verification</p>
                      </li>
                    </ul>
                  </div>
                </div>
              </TabsContent>
            </Tabs>
          </div>
        </section>
      </main>

      <footer className="border-t py-12 bg-muted/30">
        <div className="container">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-8 items-center">
            <div>
              <div className="flex items-center gap-2 mb-4">
                <Pill className="h-6 w-6 text-purple-500" />
                <span className="text-xl font-bold">MediChain</span>
              </div>
              <p className="text-muted-foreground max-w-md mb-6">
                Connecting hospitals to share critical medicines efficiently and save lives.
              </p>
            </div>
            <div className="flex flex-col items-center md:items-end">
              <Image
                src={qr}
                alt="QR Code"
                className="rounded-lg"
                width={200}
                height={200}
              />
              <p className="text-sm text-muted-foreground">Scan to download the app</p>
            </div>
          </div>
          <div className="mt-12 pt-6 border-t text-center text-sm text-muted-foreground">
            <p>© {new Date().getFullYear()} MediChain. All rights reserved.</p>
          </div>
        </div>
      </footer>
    </div>
  )
}

