import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "Tamagotchi",
  description: "A virtual pet you can feed, play with, and keep clean!",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <body className="antialiased h-dvh flex items-center justify-center">
        {children}
      </body>
    </html>
  );
}
