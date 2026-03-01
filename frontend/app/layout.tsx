export const metadata = {
  title: "USDC Yield Vault",
  description: "Aave v3 yield vault demo",
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}
