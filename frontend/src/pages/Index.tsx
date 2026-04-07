import { useTheme } from "@/contexts/ThemeContext";
import { SoftBloomLayout } from "@/layouts/SoftBloomLayout";
import { RetroPixelLayout } from "@/layouts/RetroPixelLayout";
import { ModernAcademicLayout } from "@/layouts/ModernAcademicLayout";
import { KawaiiPastelLayout } from "@/layouts/KawaiiPastelLayout";
import { CyberTerminalLayout } from "@/layouts/CyberTerminalLayout";
import { QuickActions } from "@/components/QuickActions";

const Index = () => {
  const { theme } = useTheme();

  const layouts = {
    "soft-bloom": <SoftBloomLayout />,
    "retro-pixel": <RetroPixelLayout />,
    "modern-academic": <ModernAcademicLayout />,
    "kawaii-pastel": <KawaiiPastelLayout />,
    "cyber-terminal": <CyberTerminalLayout />,
  };

  return (
    <div className="relative min-h-screen">
      <div key={theme}>
        {layouts[theme]}
      </div>
      <QuickActions />
    </div>
  );
};

export default Index;
