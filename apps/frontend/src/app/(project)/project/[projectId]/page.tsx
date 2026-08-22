"use client";

import React, { useState } from "react";
import Link from "next/link";
import { useParams } from "next/navigation";
import {
  Cpu,
  ArrowLeft,
  Sparkles,
  Play,
  Share2,
  Download,
  ShieldCheck,
  FileCode,
  Layers,
  Settings2,
  Send,
  Plus,
  RotateCw,
  Trash2,
} from "lucide-react";

export default function WorkspacePage() {
  const params = useParams();
  const projectId = params.projectId as string;

  const [activeTab, setActiveTab] = useState<"canvas" | "code" | "bom" | "docs">("canvas");
  const [aiPrompt, setAiPrompt] = useState("");
  const [messages, setMessages] = useState([
    {
      sender: "ai",
      text: "Hello! I am your AI Electronics Assistant. Describe what you'd like to build or modify.",
    },
  ]);

  const handleSendMessage = (e: React.FormEvent) => {
    e.preventDefault();
    if (!aiPrompt.trim()) return;

    setMessages((prev) => [
      ...prev,
      { sender: "user", text: aiPrompt },
      {
        sender: "ai",
        text: `Got it! Processing your request: "${aiPrompt}". Updating circuit and pin mappings...`,
      },
    ]);
    setAiPrompt("");
  };

  return (
    <div className="flex flex-col h-screen overflow-hidden bg-background">
      {/* Top Workspace Toolbar */}
      <header className="h-14 border-b border-border bg-card/80 px-4 flex items-center justify-between z-30 shrink-0">
        <div className="flex items-center gap-3">
          <Link
            href="/dashboard"
            className="p-1.5 rounded-lg hover:bg-secondary text-muted-foreground hover:text-foreground transition-colors"
          >
            <ArrowLeft className="w-4 h-4" />
          </Link>
          <div className="flex items-center gap-2">
            <div className="w-7 h-7 rounded-lg bg-primary flex items-center justify-center text-primary-foreground">
              <Cpu className="w-4 h-4" />
            </div>
            <span className="font-semibold text-sm">
              {projectId === "new" ? "New Project" : "Smart Plant Watering System"}
            </span>
            <span className="text-xs px-2 py-0.5 rounded-full bg-secondary text-muted-foreground">
              ESP32
            </span>
          </div>
        </div>

        {/* View Switcher Tabs */}
        <div className="flex items-center gap-1 p-1 rounded-lg bg-background border border-border">
          <button
            onClick={() => setActiveTab("canvas")}
            className={`px-3 py-1 text-xs font-medium rounded-md transition-colors flex items-center gap-1.5 ${
              activeTab === "canvas" ? "bg-primary text-primary-foreground" : "text-muted-foreground hover:text-foreground"
            }`}
          >
            <Layers className="w-3.5 h-3.5" />
            Circuit Canvas
          </button>
          <button
            onClick={() => setActiveTab("code")}
            className={`px-3 py-1 text-xs font-medium rounded-md transition-colors flex items-center gap-1.5 ${
              activeTab === "code" ? "bg-primary text-primary-foreground" : "text-muted-foreground hover:text-foreground"
            }`}
          >
            <FileCode className="w-3.5 h-3.5" />
            Firmware (C++)
          </button>
          <button
            onClick={() => setActiveTab("bom")}
            className={`px-3 py-1 text-xs font-medium rounded-md transition-colors flex items-center gap-1.5 ${
              activeTab === "bom" ? "bg-primary text-primary-foreground" : "text-muted-foreground hover:text-foreground"
            }`}
          >
            <Settings2 className="w-3.5 h-3.5" />
            BOM & Cost
          </button>
        </div>

        {/* Action Controls */}
        <div className="flex items-center gap-2">
          <button className="px-3 py-1.5 rounded-lg bg-emerald-500/10 hover:bg-emerald-500/20 text-emerald-400 border border-emerald-500/20 text-xs font-medium flex items-center gap-1.5 transition-colors">
            <ShieldCheck className="w-3.5 h-3.5" />
            Validated (0 Errors)
          </button>
          <button className="px-3 py-1.5 rounded-lg bg-secondary hover:bg-secondary/80 text-foreground text-xs font-medium flex items-center gap-1.5 transition-colors border border-border">
            <Download className="w-3.5 h-3.5" />
            Export
          </button>
        </div>
      </header>

      {/* Main Workspace Body */}
      <div className="flex-1 flex overflow-hidden">
        {/* Left Component Library Sidebar */}
        <aside className="w-64 border-r border-border bg-card/40 flex flex-col shrink-0">
          <div className="p-3 border-b border-border">
            <h3 className="text-xs font-semibold uppercase tracking-wider text-muted-foreground mb-2">
              Component Library
            </h3>
            <input
              type="text"
              placeholder="Search components..."
              className="w-full px-2.5 py-1.5 rounded-md bg-background border border-border text-xs focus:border-primary focus:outline-none"
            />
          </div>

          <div className="flex-1 overflow-y-auto p-3 space-y-2 text-xs">
            <div className="p-2.5 rounded-lg bg-card border border-border/80 hover:border-primary cursor-grab flex items-center justify-between">
              <div>
                <div className="font-semibold text-foreground">ESP32 Dev Module</div>
                <div className="text-[10px] text-muted-foreground">30-Pin Microcontroller</div>
              </div>
              <Plus className="w-4 h-4 text-muted-foreground" />
            </div>

            <div className="p-2.5 rounded-lg bg-card border border-border/80 hover:border-primary cursor-grab flex items-center justify-between">
              <div>
                <div className="font-semibold text-foreground">Soil Moisture Sensor</div>
                <div className="text-[10px] text-muted-foreground">Capacitive Analog Input</div>
              </div>
              <Plus className="w-4 h-4 text-muted-foreground" />
            </div>

            <div className="p-2.5 rounded-lg bg-card border border-border/80 hover:border-primary cursor-grab flex items-center justify-between">
              <div>
                <div className="font-semibold text-foreground">5V Relay Module</div>
                <div className="text-[10px] text-muted-foreground">1-Channel Actuator Switch</div>
              </div>
              <Plus className="w-4 h-4 text-muted-foreground" />
            </div>

            <div className="p-2.5 rounded-lg bg-card border border-border/80 hover:border-primary cursor-grab flex items-center justify-between">
              <div>
                <div className="font-semibold text-foreground">0.96&quot; OLED Display</div>
                <div className="text-[10px] text-muted-foreground">I2C (SSD1306)</div>
              </div>
              <Plus className="w-4 h-4 text-muted-foreground" />
            </div>
          </div>
        </aside>

        {/* Central Canvas / Code Area */}
        <div className="flex-1 flex flex-col relative bg-dot-grid bg-background overflow-hidden">
          {activeTab === "canvas" ? (
            <div className="flex-1 flex items-center justify-center relative">
              {/* Canvas Placeholder / Mounting Area */}
              <div className="text-center p-8 rounded-2xl bg-card/60 border border-border/60 max-w-md shadow-xl backdrop-blur">
                <div className="w-12 h-12 rounded-xl bg-primary/10 text-primary mx-auto flex items-center justify-center mb-3">
                  <Layers className="w-6 h-6" />
                </div>
                <h3 className="font-bold text-lg mb-1">2D Interactive Circuit Canvas</h3>
                <p className="text-xs text-muted-foreground">
                  React Flow canvas mounted with custom SVG nodes, orthogonal step wire routing, and viewBox pin handle alignment.
                </p>
              </div>
            </div>
          ) : activeTab === "code" ? (
            <div className="flex-1 p-6 overflow-auto font-mono text-xs text-emerald-400 bg-black/80">
              <pre>{`// Generated by Eureka AI for ESP32
#include <WiFi.h>
#include <Wire.h>

#define SOIL_PIN 34
#define RELAY_PIN 26

void setup() {
  Serial.begin(115200);
  pinMode(RELAY_PIN, OUTPUT);
  digitalWrite(RELAY_PIN, LOW);
  Serial.println("System Initialized");
}

void loop() {
  int moisture = analogRead(SOIL_PIN);
  if (moisture < 1500) {
    digitalWrite(RELAY_PIN, HIGH); // Water pump ON
  } else {
    digitalWrite(RELAY_PIN, LOW);  // Water pump OFF
  }
  delay(1000);
}`}</pre>
            </div>
          ) : (
            <div className="flex-1 p-6 overflow-auto">
              <h2 className="text-lg font-bold mb-4">Bill of Materials (BOM)</h2>
              <table className="w-full text-xs text-left border border-border">
                <thead className="bg-secondary/50">
                  <tr>
                    <th className="p-3 border-b border-border">Component</th>
                    <th className="p-3 border-b border-border">Designator</th>
                    <th className="p-3 border-b border-border">Qty</th>
                    <th className="p-3 border-b border-border">Unit Price</th>
                    <th className="p-3 border-b border-border">Total</th>
                  </tr>
                </thead>
                <tbody>
                  <tr className="border-b border-border/50">
                    <td className="p-3 font-medium">ESP32 Dev Board</td>
                    <td className="p-3 text-muted-foreground">U1</td>
                    <td className="p-3">1</td>
                    <td className="p-3">$4.50</td>
                    <td className="p-3 font-semibold">$4.50</td>
                  </tr>
                  <tr className="border-b border-border/50">
                    <td className="p-3 font-medium">Soil Moisture Sensor</td>
                    <td className="p-3 text-muted-foreground">SEN1</td>
                    <td className="p-3">1</td>
                    <td className="p-3">$1.20</td>
                    <td className="p-3 font-semibold">$1.20</td>
                  </tr>
                  <tr>
                    <td className="p-3 font-medium">5V Relay Module</td>
                    <td className="p-3 text-muted-foreground">K1</td>
                    <td className="p-3">1</td>
                    <td className="p-3">$1.10</td>
                    <td className="p-3 font-semibold">$1.10</td>
                  </tr>
                </tbody>
              </table>
            </div>
          )}
        </div>

        {/* Right AI Assistant Chat Panel */}
        <aside className="w-80 border-l border-border bg-card flex flex-col shrink-0">
          <div className="p-3 border-b border-border flex items-center gap-2">
            <Sparkles className="w-4 h-4 text-primary" />
            <span className="font-semibold text-xs">AI Circuit Copilot</span>
          </div>

          <div className="flex-1 p-3 overflow-y-auto space-y-3">
            {messages.map((msg, i) => (
              <div
                key={i}
                className={`p-3 rounded-xl text-xs leading-relaxed ${
                  msg.sender === "ai"
                    ? "bg-secondary text-foreground border border-border"
                    : "bg-primary text-primary-foreground ml-4"
                }`}
              >
                {msg.text}
              </div>
            ))}
          </div>

          <form onSubmit={handleSendMessage} className="p-3 border-t border-border bg-background/50">
            <div className="flex items-center gap-2">
              <input
                type="text"
                placeholder="Ask AI to modify circuit..."
                value={aiPrompt}
                onChange={(e) => setAiPrompt(e.target.value)}
                className="flex-1 px-3 py-2 rounded-lg bg-card border border-border text-xs focus:border-primary focus:outline-none"
              />
              <button
                type="submit"
                className="p-2 rounded-lg bg-primary hover:bg-primary/90 text-primary-foreground transition-colors shrink-0 shadow-sm"
              >
                <Send className="w-3.5 h-3.5" />
              </button>
            </div>
          </form>
        </aside>
      </div>
    </div>
  );
}
