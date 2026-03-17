import { useTheme } from "@/contexts/ThemeContext";
import { SoftBloomLayout } from "@/layouts/SoftBloomLayout";
import { NoirLayout } from "@/layouts/NoirLayout";
import { CottageSageLayout } from "@/layouts/CottageSageLayout";
import { ModernAcademicLayout } from "@/layouts/ModernAcademicLayout";
import { KawaiiPastelLayout } from "@/layouts/KawaiiPastelLayout";
import { CyberTerminalLayout } from "@/layouts/CyberTerminalLayout";
import { ClassicLinenLayout } from "@/layouts/ClassicLinenLayout";
import { QuickActions } from "@/components/QuickActions";
import { ThemeToggle } from "@/components/ThemeToggle";

const Index = () => {
  const { theme } = useTheme();

  const layouts = {
    "soft-bloom": <SoftBloomLayout />,
    "noir": <NoirLayout />,
    "cottage-sage": <CottageSageLayout />,
    "modern-academic": <ModernAcademicLayout />,
    "kawaii-pastel": <KawaiiPastelLayout />,
    "cyber-terminal": <CyberTerminalLayout />,
    "classic-linen": <ClassicLinenLayout />,
  };

  return (
    <div className="relative min-h-screen">
      <ThemeToggle />
      <div key={theme}>
        {layouts[theme]}
      </div>
      <QuickActions />
    </div>
  );
};

export default Index;
