import { SoftBloomLayout } from "@/layouts/SoftBloomLayout";
import { QuickActions } from "@/components/QuickActions";
import { AppTour } from "@/components/onboarding/AppTour";

const Index = () => {
  return (
    <div className="relative min-h-screen">
      <SoftBloomLayout />
      <QuickActions />
      <AppTour />
    </div>
  );
};

export default Index;
