import Link from "next/link";
import { Cpu, ArrowLeft } from "lucide-react";

export default function SignupPage() {
  return (
    <div className="min-h-screen flex items-center justify-center p-6 bg-background">
      <div className="w-full max-w-md p-8 rounded-2xl bg-card border border-border shadow-xl">
        <Link
          href="/"
          className="inline-flex items-center gap-2 text-xs text-muted-foreground hover:text-foreground mb-6 transition-colors"
        >
          <ArrowLeft className="w-4 h-4" />
          Back to Home
        </Link>

        <div className="flex items-center gap-3 mb-6">
          <div className="w-10 h-10 rounded-xl bg-primary flex items-center justify-center text-primary-foreground shadow-md shadow-primary/20">
            <Cpu className="w-6 h-6" />
          </div>
          <div>
            <h1 className="text-xl font-bold">Create your Account</h1>
            <p className="text-xs text-muted-foreground">Start building AI-powered electronics</p>
          </div>
        </div>

        <form className="space-y-4">
          <div>
            <label className="block text-xs font-medium text-muted-foreground mb-1.5">Full Name</label>
            <input
              type="text"
              placeholder="Ada Lovelace"
              className="w-full px-3.5 py-2.5 rounded-lg bg-background border border-border focus:border-primary focus:outline-none text-sm transition-colors"
            />
          </div>

          <div>
            <label className="block text-xs font-medium text-muted-foreground mb-1.5">Email Address</label>
            <input
              type="email"
              placeholder="you@example.com"
              className="w-full px-3.5 py-2.5 rounded-lg bg-background border border-border focus:border-primary focus:outline-none text-sm transition-colors"
            />
          </div>

          <div>
            <label className="block text-xs font-medium text-muted-foreground mb-1.5">Password</label>
            <input
              type="password"
              placeholder="••••••••"
              className="w-full px-3.5 py-2.5 rounded-lg bg-background border border-border focus:border-primary focus:outline-none text-sm transition-colors"
            />
          </div>

          <Link
            href="/dashboard"
            className="w-full py-2.5 rounded-lg bg-primary hover:bg-primary/90 text-primary-foreground font-medium text-sm transition-all shadow-md shadow-primary/20 flex items-center justify-center"
          >
            Create Account
          </Link>
        </form>

        <div className="mt-6 text-center text-xs text-muted-foreground">
          Already have an account?{" "}
          <Link href="/login" className="text-primary hover:underline font-medium">
            Sign in
          </Link>
        </div>
      </div>
    </div>
  );
}
