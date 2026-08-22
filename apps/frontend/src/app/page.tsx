import Link from "next/link";
import { Cpu, Sparkles, ShieldCheck, FileCode, Layers, ArrowRight, Zap, Play } from "lucide-react";

export default function LandingPage() {
  return (
    <div className="flex flex-col min-h-screen">
      {/* Navigation Header */}
      <header className="border-b border-border/50 backdrop-blur-md sticky top-0 z-50 bg-background/80">
        <div className="max-w-7xl mx-auto px-6 h-16 flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="w-9 h-9 rounded-lg bg-gradient-to-br from-primary to-blue-600 flex items-center justify-center shadow-lg shadow-primary/20">
              <Cpu className="w-5 h-5 text-primary-foreground" />
            </div>
            <span className="font-bold text-xl tracking-tight bg-gradient-to-r from-foreground to-muted-foreground bg-clip-text text-transparent">
              Eureka
            </span>
            <span className="text-xs px-2 py-0.5 rounded-full bg-primary/10 text-primary border border-primary/20 font-medium">
              AI Electronics Studio
            </span>
          </div>

          <nav className="flex items-center gap-6">
            <Link href="/dashboard" className="text-sm text-muted-foreground hover:text-foreground transition-colors">
              Projects
            </Link>
            <Link href="/admin" className="text-sm text-muted-foreground hover:text-foreground transition-colors">
              Admin
            </Link>
            <Link
              href="/login"
              className="text-sm font-medium px-4 py-2 rounded-lg bg-secondary hover:bg-secondary/80 text-foreground transition-colors border border-border"
            >
              Sign In
            </Link>
            <Link
              href="/dashboard"
              className="text-sm font-medium px-4 py-2 rounded-lg bg-primary hover:bg-primary/90 text-primary-foreground transition-all shadow-md shadow-primary/20 flex items-center gap-2"
            >
              <Sparkles className="w-4 h-4" />
              Launch Studio
            </Link>
          </nav>
        </div>
      </header>

      {/* Hero Section */}
      <main className="flex-1">
        <section className="py-20 px-6 max-w-7xl mx-auto text-center relative overflow-hidden">
          <div className="absolute inset-0 -z-10 flex items-center justify-center opacity-30 pointer-events-none">
            <div className="w-[600px] h-[600px] bg-primary/20 rounded-full blur-3xl animate-pulse" />
          </div>

          <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-secondary/80 border border-border text-xs text-muted-foreground mb-6">
            <Zap className="w-3.5 h-3.5 text-amber-400" />
            <span>Figma visual canvas + Cursor AI modification + Electrical safety</span>
          </div>

          <h1 className="text-5xl md:text-6xl font-extrabold tracking-tight max-w-4xl mx-auto leading-tight">
            Turn your electronics ideas into{" "}
            <span className="bg-gradient-to-r from-blue-400 via-primary to-indigo-400 bg-clip-text text-transparent">
              interactive circuits & code
            </span>{" "}
            instantly.
          </h1>

          <p className="text-lg text-muted-foreground max-w-2xl mx-auto mt-6">
            Describe your project in plain language. Eureka selects real components, connects pin-to-pin wiring, validates electrical constraints, and generates production firmware and assembly guides.
          </p>

          {/* Interactive Prompt Demo Box */}
          <div className="max-w-3xl mx-auto mt-10 p-2 rounded-2xl bg-card border border-border shadow-2xl">
            <div className="p-4 bg-background/50 rounded-xl border border-border/50 flex items-center gap-3">
              <Sparkles className="w-5 h-5 text-primary shrink-0" />
              <input
                type="text"
                readOnly
                value="Build an ESP32 smart plant watering system using soil moisture sensor, relay, and OLED display"
                className="w-full bg-transparent text-sm text-foreground focus:outline-none cursor-default"
              />
              <Link
                href="/dashboard"
                className="px-4 py-2 rounded-lg bg-primary hover:bg-primary/90 text-primary-foreground text-xs font-semibold shrink-0 flex items-center gap-1.5 shadow-sm shadow-primary/20"
              >
                <span>Generate</span>
                <ArrowRight className="w-3.5 h-3.5" />
              </Link>
            </div>
          </div>

          {/* Features Grid */}
          <div className="grid md:grid-cols-3 gap-6 max-w-5xl mx-auto mt-20 text-left">
            <div className="p-6 rounded-xl bg-card border border-border/80 hover:border-primary/50 transition-colors">
              <div className="w-10 h-10 rounded-lg bg-blue-500/10 text-blue-400 flex items-center justify-center mb-4">
                <Layers className="w-5 h-5" />
              </div>
              <h3 className="font-semibold text-lg mb-2">2D Interactive Canvas</h3>
              <p className="text-sm text-muted-foreground">
                Drag, rotate, and wire real components on an intuitive React Flow canvas. Handles map accurately to SVG pin coordinates.
              </p>
            </div>

            <div className="p-6 rounded-xl bg-card border border-border/80 hover:border-primary/50 transition-colors">
              <div className="w-10 h-10 rounded-lg bg-amber-500/10 text-amber-400 flex items-center justify-center mb-4">
                <ShieldCheck className="w-5 h-5" />
              </div>
              <h3 className="font-semibold text-lg mb-2">Deterministic Safety Checks</h3>
              <p className="text-sm text-muted-foreground">
                Automatic validation against voltage mismatches (e.g. 5V into 3.3V GPIO), current overdraws, and pin conflicts before building.
              </p>
            </div>

            <div className="p-6 rounded-xl bg-card border border-border/80 hover:border-primary/50 transition-colors">
              <div className="w-10 h-10 rounded-lg bg-emerald-500/10 text-emerald-400 flex items-center justify-center mb-4">
                <FileCode className="w-5 h-5" />
              </div>
              <h3 className="font-semibold text-lg mb-2">Synced Firmware & Docs</h3>
              <p className="text-sm text-muted-foreground">
                Every circuit edit instantly updates C++ microcontroller code (Arduino/ESP32), BOM cost estimates, and assembly troubleshooting manuals.
              </p>
            </div>
          </div>
        </section>
      </main>

      {/* Footer */}
      <footer className="border-t border-border/50 py-8 px-6 text-center text-xs text-muted-foreground">
        <p>© 2026 Eureka AI Electronics Project Builder. Built for makers, students, and engineers.</p>
      </footer>
    </div>
  );
}
