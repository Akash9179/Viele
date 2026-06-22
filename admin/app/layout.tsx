import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "Viele Admin",
  description: "Viele super-admin console",
};

export default function RootLayout({
  children,
}: Readonly<{ children: React.ReactNode }>) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}
