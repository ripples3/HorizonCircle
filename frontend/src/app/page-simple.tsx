import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { APP_NAME } from '@/constants';

export default function Home() {
  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-100 flex items-center justify-center p-4">
      <Card className="w-full max-w-md">
        <CardHeader className="text-center">
          <CardTitle className="text-2xl">{APP_NAME}</CardTitle>
          <CardDescription>
            DeFi-powered cooperative lending platform
          </CardDescription>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="space-y-2">
            <h3 className="font-semibold">Features:</h3>
            <ul className="text-sm space-y-1 text-muted-foreground">
              <li>• 5% APY on deposits</li>
              <li>• Ultra-low borrowing rates (0.1% effective)</li>
              <li>• Social lending circles</li>
              <li>• Instant approvals</li>
            </ul>
          </div>
          <Button className="w-full" size="lg">
            Get Started (Demo)
          </Button>
          <p className="text-xs text-muted-foreground text-center">
            67-80% savings vs traditional BNPL
          </p>
        </CardContent>
      </Card>
    </div>
  );
}