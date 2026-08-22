import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "Eureka — AI Electronics Project Builder",
  description: "Describe an electronics project and get a 2D interactive circuit, validated wiring, BOM, firmware code, and assembly guide.",
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en" className="dark">
      <body className="min-h-screen bg-background text-foreground flex flex-col">
        {children}
      </body>
    </html>
  );
}
