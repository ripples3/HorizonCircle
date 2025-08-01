export default function NotFound() {
  return (
    <div className="min-h-screen bg-gradient-light flex items-center justify-center p-4">
      <div className="text-center">
        <h2 className="text-2xl font-bold text-foreground mb-4">404 - Page Not Found</h2>
        <p className="text-muted-foreground mb-4">The page you're looking for doesn't exist.</p>
        <a href="/" className="text-primary hover:underline">
          Go back home
        </a>
      </div>
    </div>
  );
}