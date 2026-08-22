import Link from "next/link";
import { Cpu, Plus, Search, Star, Folder, Clock, Layers, ArrowUpRight } from "lucide-react";

export default function DashboardPage() {
  // Sample projects for display
  const sampleProjects = [
    {
      id: "esp32-plant-monitor",
      title: "Smart Irrigation & Soil Monitor",
      category: "IoT / Agriculture",
      componentsCount: 5,
      updatedAt: "10 mins ago",
      favorite: true,
    },
    {
      id: "weather-station-oled",
      title: "ESP32 WiFi Weather Station",
      category: "Home Automation",
      componentsCount: 4,
      updatedAt: "2 hours ago",
      favorite: false,
    },
    {
      id: "rgb-matrix-clock",
      title: "NeoPixel Digital Desk Clock",
      category: "Display / Lighting",
      componentsCount: 3,
      updatedAt: "1 day ago",
      favorite: false,
    },
  ];

  return (
    <div className="min-h-screen flex flex-col bg-background">
      {/* Header */}
      <header className="border-b border-border/50 bg-card/50 backdrop-blur sticky top-0 z-40">
        <div className="max-w-7xl mx-auto px-6 h-16 flex items-center justify-between">
          <Link href="/" className="flex items-center gap-3">
            <div className="w-8 h-8 rounded-lg bg-primary flex items-center justify-center text-primary-foreground">
              <Cpu className="w-4 h-4" />
            </div>
            <span className="font-bold text-lg">Eureka Studio</span>
          </Link>

          <div className="flex items-center gap-4">
            <Link
              href="/project/new"
              className="px-4 py-2 rounded-lg bg-primary hover:bg-primary/90 text-primary-foreground text-sm font-medium flex items-center gap-2 shadow-sm shadow-primary/20 transition-all"
            >
              <Plus className="w-4 h-4" />
              New Project
            </Link>
          </div>
        </div>
      </header>

      {/* Main Content */}
      <main className="flex-1 max-w-7xl w-full mx-auto px-6 py-8">
        <div className="flex flex-col md:flex-row md:items-center justify-between gap-4 mb-8">
          <div>
            <h1 className="text-2xl font-bold">My Electronics Projects</h1>
            <p className="text-sm text-muted-foreground">Manage and edit your interactive circuit designs</p>
          </div>

          <div className="flex items-center gap-3">
            <div className="relative w-72">
              <Search className="w-4 h-4 absolute left-3 top-1/2 -translate-y-1/2 text-muted-foreground" />
              <input
                type="text"
                placeholder="Search projects..."
                className="w-full pl-9 pr-4 py-2 rounded-lg bg-card border border-border text-sm focus:border-primary focus:outline-none transition-colors"
              />
            </div>
          </div>
        </div>

        {/* Project Grid */}
        <div className="grid md:grid-cols-3 gap-6">
          {/* Create Project Card */}
          <Link
            href="/project/new"
            className="p-6 rounded-2xl border-2 border-dashed border-border hover:border-primary/50 hover:bg-card/30 transition-all flex flex-col items-center justify-center text-center group min-h-[200px]"
          >
            <div className="w-12 h-12 rounded-xl bg-primary/10 text-primary flex items-center justify-center mb-3 group-hover:scale-110 transition-transform">
              <Plus className="w-6 h-6" />
            </div>
            <h3 className="font-semibold text-foreground">Create New Project</h3>
            <p className="text-xs text-muted-foreground mt-1 max-w-[200px]">
              Describe with AI or start from an empty canvas
            </p>
          </Link>

          {/* Existing Project Cards */}
          {sampleProjects.map((project) => (
            <Link
              key={project.id}
              href={`/project/${project.id}`}
              className="p-6 rounded-2xl bg-card border border-border hover:border-primary/50 transition-all flex flex-col justify-between group shadow-sm hover:shadow-md"
            >
              <div>
                <div className="flex items-start justify-between gap-2 mb-3">
                  <span className="text-xs px-2.5 py-1 rounded-full bg-secondary text-muted-foreground border border-border">
                    {project.category}
                  </span>
                  {project.favorite && <Star className="w-4 h-4 text-amber-400 fill-amber-400" />}
                </div>
                <h3 className="font-semibold text-lg text-foreground group-hover:text-primary transition-colors flex items-center justify-between">
                  {project.title}
                  <ArrowUpRight className="w-4 h-4 opacity-0 group-hover:opacity-100 transition-opacity text-primary" />
                </h3>
              </div>

              <div className="flex items-center justify-between text-xs text-muted-foreground pt-4 border-t border-border/50 mt-4">
                <span className="flex items-center gap-1.5">
                  <Layers className="w-3.5 h-3.5" />
                  {project.componentsCount} components
                </span>
                <span className="flex items-center gap-1.5">
                  <Clock className="w-3.5 h-3.5" />
                  {project.updatedAt}
                </span>
              </div>
            </Link>
          ))}
        </div>
      </main>
    </div>
  );
}
